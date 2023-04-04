# Network Troubleshooting

## kube-proxy 실패

네트워크 실패 중 가장 근본적인 문제가 될 수 있는 부분은 kube-proxy 실패입니다. kube-proxy는 클러스터 내부의 네트워크 트래픽을 관리하는 컴포넌트입니다.

kube-proxy가 실패할 원인 중 하나로 kubeconfig 구성이 제대로 되지 않았을 경우입니다.

```sh
$ k -n kube-system get ds kube-proxy -oyaml
apiVersion: apps/v1
kind: DaemonSet
...
      - command:
        - /usr/local/bin/kube-proxy
        - --config=/var/lib/kube-proxy/config.conf # 구성 파일 옵션
        - --hostname-override=$(NODE_NAME)
...
        volumeMounts:
        - mountPath: /var/lib/kube-proxy # 구성 파일 볼륨 마운트
          name: kube-proxy
...
      volumes:
      - configMap: # 구성 파일 볼륨(컨피그맵)
          defaultMode: 420
          name: kube-proxy
        name: kube-proxy
...
```

kube-proxy의 구성 파일은 ConfigMap으로 마운트되어 있습니다. 구성 파일(`config.conf`)의 kubeconfig 참조를 망가뜨려서 kube-proxy가 정상적으로 동작하지 않는 경우를 만들어 보겠습니다.

```sh
$ k -n kube-system edit cm kube-proxy -oyaml
...
data:
  config.conf: |
    ...
    clientConnection:
      acceptContentTypes: ""
      burst: 0
      contentType: ""
      kubeconfig: /var/lib/kube-proxy/BROKEN-CONFIG-XXXX.conf # 이 부분을 수정
      qps: 0
...

# ConfigMap을 다시 읽기 위해 kube-proxy를 재시작
$ k -n kube-system rollout restart ds kube-proxy
daemonset.apps/kube-proxy restarted

# 상태 확인
$ k -n kube-system rollout status ds kube-proxy
Waiting for daemon set "kube-proxy" rollout to finish: 1 out of 3 new pods have been updated...
^C

$ k -n kube-system get po -l k8s-app=kube-proxy -w -owide
NAME               READY   STATUS             RESTARTS      AGE    IP            NODE     NOMINATED NODE   READINESS GATES
kube-proxy-7nrvk   0/1     CrashLoopBackOff   1 (3s ago)    5s     10.178.0.8    node-1   <none>           <none>
kube-proxy-txstj   0/1     Error              3 (32s ago)   50s    10.178.0.10   node-3   <none>           <none>
kube-proxy-vs75b   1/1     Running            1 (26h ago)   2d1h   10.178.0.9    node-2   <none>           <none>
```

kube-proxy 파드가 실행되지 않습니다. kube-proxy가 실행되지 않는 노드엔 파드가 스케쥴 되지 않을 것이고 기존 파드들의 통신에 문제가 생깁니다. 다시 수정하여 kube-proxy를 정상적으로 동작하도록 만들어 보겠습니다.

```sh
$ k -n kube-system edit cm kube-proxy -oyaml
...
data:
  config.conf: |
    ...
    clientConnection:
      acceptContentTypes: ""
      burst: 0
      contentType: ""
      kubeconfig: /var/lib/kube-proxy/kubeconfig.conf # 이 부분을 원복
      qps: 0
...

$ k -n kube-system rollout restart ds kube-proxy
$ k -n kube-system rollout status ds kube-proxy # 롤아웃 상태 확인
$ k -n kube-system get po -l k8s-app=kube-proxy -w -owide # 파드 상태 확인
```

## CNI 플러그인 실패

kube-proxy 외에 중요한 네트워크 컴포넌트로 CNI 플러그인 컴포넌트가 있습니다. 이 파드들이 실패하면 파드에 IP를 할당할 수 없어 `ContainerCreating` 에서 계속 머무를 수 있습니다.

## 네트워크 디버깅

`busybox` 이미지를 사용하여 네트워크 디버깅을 할 수 있습니다. 서비스나 파드의 포트가 열렸는지, DNS가 정상적으로 동작하는지 등을 확인할 수 있습니다.

```sh
# 테스트 할 파드와 서비스 생성
$ k run pod1 --image nginx
$ k expose pod pod1 --name svc1 --port 80

$ k run test -it --rm --restart Never --image busybox -- sh
# (test pod)
$ nc -zv -w 3 svc1 80 # 서비스 포트가 열려 있는지 확인
svc1 (10.97.158.88:80) open

$ nslookup svc1
Server:         10.96.0.10
Address:        10.96.0.10:53
...
Name:   svc1.default.svc.cluster.local
Address: 10.97.158.88
...
```

포트 열림을 확인하는 `nc` 명령은 `nc -zv -w <sec> <host> <port>`
- `-z`: 포트 열림 여부만 확인하고 연결을 끊습니다(Zero-I/O)
- `-v` 옵션은 상세한 정보를 출력합니다.
- `-w` 옵션은 타임아웃을 설정합니다.

nslookup은 DNS를 확인하는 명령입니다. `nslookup <host>` 형식으로 사용합니다. 여러 search 도메인을 모두 찾기 때문에 FQDN을 사용하지 않으면 실패한 쿼리 결과까지 보여줍니다.

<details>
<summary>Q1. 서비스 미리 노출하고 kube-proxy를 망가뜨려 보세요. 서비스 요청 시 어떻게 되나요?</summary>

</details>
