# DaemonSet

데몬셋(`DaemonSet`)은 클러스터 내 모든 노드에서 특정 파드가 실행되도록 보장하는 워크로드 객체입니다. 시스템 데몬, 로깅 에이전트 및 클러스터 내 모든 노드에서 실행해야 하는 유형의 작업에 자주 사용됩니다.

데몬셋은 디플로이먼트(`Deployment`)처럼, 노드 선택자(node selector), 어피니티(affinities) 및 톨러레이션(toleartion)을 포함하여 파드의 스케줄링과 배포를 제어하기 위한 여러 구성 옵션을 제공하고, 롤링 업데이트를 지원하여 새로운 파드로 오래된 파드를 교체할 때 다운타임 없이 수행할 수 있습니다. 즉 디플로이먼트와 비슷하지만, 데몬셋은 노드에 하나의 파드만 배포할 수 있습니다.

## 데몬셋 생성

로그를 수집하는 예시 데몬셋을 만들어 보겠습니다. 먼저 로그를 찍는 파드를 생성합니다.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: logger
  labels:
    app: logger
spec:
  containers:
  - name: logger
    image: busybox
    command:
    - sh
    - -c
    - 'while true; do echo "$(date): ..."; sleep 1; done'
```


데몬셋을 생성하려면, `kubectl create` 명령을 사용하여 데몬셋을 정의하는 YAML 파일을 지정합니다. 예를 들어, 다음은 데몬셋을 생성하는 YAML 파일의 예입니다.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentbox
spec:
  selector:
    matchLabels:
      app: fluentbox
  template:
    metadata:
      labels:
        app: fluentbox
    spec:
      containers:
      - name: fluentbox
        image: busybox
        command:
        - sh
        - -c
        - "tail -f /var/log/containers/*"
        volumeMounts:
        - name: log
          mountPath: /var/log
      volumes:
      - name: log
        hostPath:
          path: /var/log
```

데몬셋의 스펙은 레플리카가 없다는 점을 제외하면 디플로이먼트 것과 거의 유사합니다. `fluentbox` 데몬셋을 적용하면, 노드마다 파드가 실행되어 노드의 /var/log/containers의 로그 파일 스트림을 출력합니다(다만 간단하게 만들었기 때문에 `fluentbox` 데몬셋 배포 후 실행되는 파드 로그는 수집할 수 없습니다).

```sh
$ k get po -owide
NAME              READY   STATUS    RESTARTS   AGE   IP             NODE     NOMINATED NODE   READINESS GATES
fluentbox-bf84n   1/1     Running   0          69s   172.16.5.16    node-2   <none>           <none>
fluentbox-rn66m   1/1     Running   0          69s   172.16.45.15   node-3   <none>           <none>
logger            1/1     Running   0          89s   172.16.5.15    node-2   <none>           <none>
```

이 경우 `logger` 파드가 `node-2`에서 실행 중입니다. `node-2`에서 실행 중인 `fluentbox` 파드 로그에 `logger` 파드 로그가 수집되는 것을 확인할 수 있습니다.

```sh
$ k logs fluentbox-bf84n
...
2023-04-08T03:53:56.489633885Z stdout F Sat Apr  8 03:51:01 UTC 2023: ...
2023-04-08T03:53:57.489821232Z stdout F Sat Apr  8 03:51:01 UTC 2023: ...
2023-04-08T03:53:58.489925434Z stdout F Sat Apr  8 03:51:01 UTC 2023: ...
2023-04-08T03:53:59.490107802Z stdout F Sat Apr  8 03:51:01 UTC 2023: ...
```

## 데몬셋 톨러레이션
`fluentbox` 데몬셋 파드는 `node-1`을 제외한 `node-2`, `node-3`에서 실행되고 있음을 알 수 있습니다.

```sh
$ k get po -l app=fluentbox
NAME              READY   STATUS    RESTARTS   AGE
fluentbox-bf84n   1/1     Running   0          3m17s
fluentbox-rn66m   1/1     Running   0          3m17s
```

하지만 로그 수집은 컨트롤플레인 노드에서도 필요합니다. 따라서 데몬셋 파드는 대부분 테인트 노드에 스케줄링되도록 구성됩니다. `node-1`에 `fluentbox` 데몬셋 파드를 스케줄링하려면 데몬셋 파드에 넓은 범위의 톨러레이션을 추가합니다.

```yaml
# k edit ds fluentbox
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentbox
spec:
  selector:
    matchLabels:
      app: fluentbox
  template:
    metadata:
      labels:
        app: fluentbox
    spec:
      tolerations:          # 톨러레이션 추가
      - operator: Exists    # 키/값에 상관 없이
        effect: NoSchedule  # 모든 NoSchedule 테인트에 톨러레이션
      containers:
      - name: fluentbox
        image: busybox
        command:
        - sh
        - -c
        - "tail -f /var/log/containers/*"
        volumeMounts:
        - name: log
          mountPath: /var/log
      volumes:
      - name: log
        hostPath:
          path: /var/log
```

`node-1`에서도 `fluentbox` 데몬셋이 실행됩니다. 톨러레이션을 적용하기 위해 나머지 파드도 하나씩 재시작됩니다.

```sh
$ k get po -l app=fluentbox -owide
NAME              READY   STATUS    RESTARTS   AGE     IP             NODE     NOMINATED NODE   READINESS GATES
fluentbox-ddfzh   1/1     Running   0          112s    172.16.5.17    node-2   <none>           <none>
fluentbox-ff556   1/1     Running   0          2m30s   172.16.25.8    node-1   <none>           <none>
fluentbox-j7fx6   1/1     Running   0          77s     172.16.45.16   node-3   <none>           <none>
```


## 데몬셋 용도
데몬셋은 예시로 만들어본 것처럼 로그 수집, 모니터링 뿐만 아니라, 노드 프록시 등에 클러스터 네트워크 구현 등에도 사용됩니다. 데몬셋은 노드마다 하나의 파드만 실행되도록 보장하기 때문에, 노드마다 하나의 파드만 실행되어야 하는 서비스를 구현할 때 유용합니다.

```sh
$ k get ds -A
NAMESPACE       NAME              DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-system   calico-node       3         3         3       3            3           kubernetes.io/os=linux   11h
calico-system   csi-node-driver   3         3         3       3            3           kubernetes.io/os=linux   11h
default         fluentbox         3         3         3       3            3           <none>                   15m
kube-system     kube-proxy        3         3         3       3            3           kubernetes.io/os=linux   11h
```


<details>
<summary>Q1. 다음 데몬셋을 생성하세요.
<br> - 이름: <code>nginx-node</code>
<br> - 이미지: <code>nginx</code>
<br> - 톨러레이션: <code>node-1</code>에 스케줄링 되도록
</summary>

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx-node
spec:
  selector:
    matchLabels:
      app: nginx-node
  template:
    metadata:
      labels:
        app: nginx-node
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: nginx-node
        image: nginx
```

</details>

<details>
<summary>Q2. 다음 데몬셋의 톨러레이션을 각각 확인해보세요(<code>ns/name</code>). 어떤 톨러레이션이 파드를 컨트롤플레인에 할당 하나요?
<br> - <code>calico-system/calico-node</code>
<br> - <code>calico-system/csi-node-driver</code>
<br> - <code>kube-system/kube-proxy</code>
</summary>

```sh
# calico-system/calico-node
$ k -n calico-system get ds calico-node  -oyaml | yq .spec.template.spec.tolerations
- key: CriticalAddonsOnly
  operator: Exists
- effect: NoSchedule # 컨트롤플레인에서 실행되게 함
  operator: Exists
- effect: NoExecute
  operator: Exists

# calico-system/csi-node-driver
$ k -n calico-system get ds csi-node-driver  -oyaml | yq .spec.template.spec.tolerations
- key: CriticalAddonsOnly
  operator: Exists
- effect: NoSchedule # 컨트롤플레인에서 실행되게 함
  operator: Exists
- effect: NoExecute
  operator: Exists

# kube-system/kube-proxy
$ k -n kube-system get ds kube-proxy  -oyaml | yq .spec.template.spec.tolerations
- operator: Exists # 컨트롤플레인에서 실행되게 함
```

</details>
