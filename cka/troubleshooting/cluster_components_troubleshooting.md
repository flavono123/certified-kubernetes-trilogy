# Cluster Components Troubleshooting

## 노드 실패
클러스터의 노드가 정상 동작하는지 확인하기 위해 확인을 먼저합니다.

```sh
$ k get no
NAME     STATUS   ROLES           AGE     VERSION
node-1   Ready    control-plane   4d21h   v1.26.1
node-2   Ready    <none>          4d21h   v1.26.1
node-3   Ready    <none>          4d21h   v1.26.1
```

현재 노드는 잘 실행 중이지만 `node-2` 노드가 정상 동작하지 않는다고 가정으로 몇가지 상황을 만들어 보겠습니다. 터미널을 하나 더 띄워 `node-2`에 접속합니다.

```sh
# gcloud compute ssh node-2; sudo -i
$ systemctl status kubelet.service
...
     Active: active (running) since Mon 2023-04-03 13:53:31 UTC; 1 day 1h ago
...
```

### kubelet 서비스가 정상 동작하지 않는 경우

kubelet이 정상 동작하고 있습니다(active, running). 만약 kubelet 서비스가 동작하지 않는다면 `node-2` 상태에 이상이 생길 것입니다. 일부러 서비스를 중단하여 상황을 만들어 봅니다.
```sh
$ systemctl stop kubelet.service
$ systemctl status kubelet.service
...
     Active: inactive (dead) since Tue 2023-04-04 15:26:13 UTC; 7s ago
...
```

노드 상태를 확인해보면 `node-2` 노드가 `NotReady` 상태로 변경되었습니다.
```sh
# (node-1)
$ k get no
NAME     STATUS     ROLES           AGE     VERSION
node-1   Ready      control-plane   4d22h   v1.26.1
node-2   NotReady   <none>          4d21h   v1.26.1
node-3   Ready      <none>          4d21h   v1.26.1
```

따라서 `NotReady` 상태인 노드라면 kubelet 서비스가 정상 동작하지 않는 것을 의심해볼 수 있습니다. 이제 `node-2` 노드에 접속하여 kubelet 서비스를 다시 시작합니다.

```sh
# (node-2)
$ systemctl start kubelet.service
$ systemctl status kubelet.service
...
     Active: active (running) since Tue 2023-04-04 15:29:35 UTC; 1s ago
...

# (node-1)
$ k get no node-2
NAME     STATUS   ROLES    AGE     VERSION
node-2   Ready    <none>   4d22h   v1.26.1
```

### kubelet 설정 오류
이번엔 kubelet 설정 파일에 오류가 있는 경우를 만들어 보겠습니다. `node-2` 노드에 접속하여 kubelet 설정 파일 경로를 확인합니다. 서비스 파일 경로를 확인합니다.

```sh
# (node-2)
$ systemctl cat kubelet.service
# /lib/systemd/system/kubelet.service
...
# /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
...
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
```

kubelt의 설정 파일에 들어가 인증서 경로를 잘못 입력한 경우를 만들어 보겠습니다.

```sh
# (node-2)
$ vi /var/lib/kubelet/config.yaml
...
    clientCAFile: /etc/kubernetes/pki/XXX-THIS-IS-NOT-EXISTS-XXX.crt # 여기를 수정합니다.
...

# kubelet 재시작
$ systemctl restart kubelet.service
$ systemctl status kubelet.service
...
     Active: activating (auto-restart) (Result: exit-code) since Tue 2023-04-04 15:50:18 UTC; 9s ago
...
```

```sh
# (node-1)
$ k get no node-2
NAME     STATUS     ROLES           AGE     VERSION
node-2  NotReady   control-plane   4d22h   v1.26.1
```

서비스 상태는 activating이지만 계속 재시작하고 있고, 노드 상태는 `NotReady` 상태입니다. 우리가 만든 오류는 kubelet 서비스 로그에서 확인할 수 있습니다.

```sh
# (node-2)
$ journalctl -u kubelet.service -f
...
Apr 04 15:52:31 node-2 kubelet[1000272]: E0404 15:52:31.917604 1000272 run.go:74] "command failed" err="failed to construct kubelet dependencies: unable to load client CA file /etc/kubernetes/pki/XXX-THIS-IS-NOT-EXISTS-XXX.crt: open /etc/kubernetes/pki/XXX-THIS-IS-NOT-EXISTS-XXX.crt: no such file or directory"
...
```

따라서 노드 상태가 `NotReady`일 땐, kubelet의 설정 파일에 오류가 없는지 로그를 통해 확인해볼 수 있습니다.

```sh
# 원복하기
# (node-2)
$ vi /var/lib/kubelet/config.yaml
...
    clientCAFile: /etc/kubernetes/pki/ca.crt # 원래대로 수정
...

$ systemctl restart kubelet.service
$ systemctl status kubelet.service # 서비스 상태 확인
$ journalctl -u kubelet.service -f # 로그 확인
```

```sh
# (node-1)
$ k get no node-2 # 노드 상태 확인
```

### kubelet 쿠버네티스 설정 오류(kubeconfig)
이번엔 kubelet의 다른 설정 파일에서 오류가 있는 경우를 만들어 보겠습니다. `node-2` 노드에 접속하여 또 다른 kubelet 설정 파일 경로를 확인합니다.

```sh
$ systemctl cat kubelet.service
# /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
...
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
...
```

kubelet의 kubeconfig(/etc/kubernetes/kubelet.conf) 파일에 들어가 API 서버 주소를 잘못 입력한 경우를 만들어 보겠습니다.

```sh
# (node-2)
$ vi /etc/kubernetes/kubelet.conf
apiversion: v1
clusters:
- cluster:
    server: https://111.222.333.444:5555 # 이 부분을 수정
    ...

$ systemctl restart kubelet.service
$ systemctl status kubelet.service
# 이 작업 후 node-2가 NotReady가 되기까지 시간이 좀 걸릴 수 있습니다.
```

kubelet의 서비스 상태는 `active` 노드 `node-2`는 `NotReady` 상태가 됐습니다.

```sh
# (node-1)
$ k get no node-2
NAME     STATUS     ROLES           AGE     VERSION
node-2  NotReady   control-plane   4d22h   v1.26.1
```

이번 문제도 kubelet 서비스 로그에서 확인할 수 있습니다.

```sh
# (node-2)
$ journalctl -u kubelet.service -f
...
Apr 04 16:13:13 node-2 kubelet[261973]: I0404 16:13:13.017605  261973 kubelet_node_status.go:70] "Attempting to register node" node="node-2"
Apr 04 16:13:13 node-2 kubelet[261973]: E0404 16:13:13.029619  261973 kubelet_node_status.go:92] "Unable to register node with API server" err="Post \"https://111.222.333.444:5555/api/v1/nodes\": dial tcp: lookup 111.222.333.444: no such host" node="node-2"
...
```

다시 원복하여 노드 상태를 `Ready`로 돌리겠습니다. kube-apiserver의 기본 포트가 6443인 것을 외우고 있으면 좋습니다.
```sh
# (node-2)
$ vi /etc/kubernetes/kubelet.conf
apiversion: v1
clusters:
- cluster:
    server: https://x.x.x.x:6443 # 원래대로 수정
    ...

$ systemctl restart kubelet.service
$ systemctl status kubelet.service # 서비스 상태 확인
$ journalctl -u kubelet.service -f # 로그 확인
```

```sh
# (node-1)
$ k get no node-2 # 노드 상태 확인
```

## 컨트롤플레인 컴포넌트 실패

컨트롤플레인 컴포넌트 역시 노드 문제와 마찬가지로 접근할 수 있습니다. 다만 노드 상태에 영향을 주는 kubelet은 서비스지만, 다른 대부분의 컴포넌트는 스태틱 파드로 실행됩니다. 따라서 파드의 상태를 우선 확인합니다.

만약 kube-apiserver가 고장나서 `kubectl`로 파드를 확인할 수 없다면, 다음과 같이 `kubelet`의 로그를 확인하거나 매니페스트 파일(/etc/kubernetes/manifests/)을 확인합니다.

다른 컴포넌트도, kubelet처럼, kubeconfg 파일이 있습니다. kubeconfig 구성이 잘못 되어 있으면, 위에서 살펴본, 인증서 문제가 똑같이 발생할 수 있습니다.
- kube-controller-manager: /etc/kubernetes/controller-manager.conf
- kube-scheduler: /etc/kubernetes/scheduler.conf

파드의 로그를 확인할 수도 있지만 `kubectl`을 사용할 수 없다면, 컨트롤플레인 노드의 컨테이너 ID를 확인하여 로그를 확인할 수 있습니다.

```sh
$ crictl ps # 컴포넌트 컨테이너의 ID 확인
$ crictl logs <container_id> # 로그 확인
```

또는 컨테이너 로그 파일의 경로에서 찾아볼 수도 있습니다(/var/log/containers/).

---

## 참고
-
