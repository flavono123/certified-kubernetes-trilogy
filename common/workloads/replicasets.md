# ReplicaSets

_레플리카셋(ReplicaSets)_은 특정 숫자의 파드를 유지하도록 보장합니다. 따라서 고가용성을 확보하고 앱의 확장이 가능합니다(scalable).

### 레플리카셋 만들기

아래 매니페스트 파일로 3개의 nginx 파드가 있는 레플리카셋을 만들어 봅시다.

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
  labels:
    name: nginx-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
```

* `.apiVersion` : `apps/v1` (파드의 `v1`과 다릅니다). 확인만 하세요. 나중에 Kubernetes API 그룹과 버전을 다룰 때 자세히 보겠습니다.
* `.spec.replicas` : 파드 복제본(replicas) 개수
* `.spec.selector` : 파드 셀렉터
* `.spec.template` : 파드 스펙

대부분의 Kubernetes 객체는, 레플리카셋처럼, 두가지 특징이 있습니다.

1. `.spec.selector`에서 객체가 선택할 파드 레이블을 서술
2. `.spec.template` 에 파드 스펙 선언

레플리카셋은 명령적 생성 방법이 없습니다. [문서](https://kubernetes.io/ko/docs/concepts/workloads/controllers/replicaset/#%EC%98%88%EC%8B%9C)에서 템플릿 매니페스트를 복사한 후 수정하여 만듭시다. 아래처럼 레플리카셋을 생성합니다.

```shell
$ cat <<EOF | k apply -f -
> apiVersion: apps/v1
> kind: ReplicaSet
> metadata:
>   name: nginx-rs
>   labels:
>     name: nginx-rs
> spec:
>   replicas: 3
>   selector:
>     matchLabels:
>       app: nginx
>   template:
>     metadata:
>       labels:
>         app: nginx
>     spec:
>       containers:
>       - name: nginx
>         image: nginx
> EOF
replicaset.apps/nginx-rs created
$ k get rs nginx-rs
NAME       DESIRED   CURRENT   READY   AGE
nginx-rs   3         3         3       47m
$ k get po -l app=nginx
NAME             READY   STATUS    RESTARTS   AGE
nginx-rs-dl5pz   1/1     Running   0          48m
nginx-rs-mddjp   1/1     Running   0          48m
nginx-rs-wr62t   1/1     Running   0          48m
```

레플리카셋의 상태와 파드가 실행 중임을 확인할 수 있습니다. 파드는 레플리카셋 이름 뒤에 5자리 16진수 접미사가 붙습니다.

파드가 죽으면 어떻게 될까요? 하날 삭제해봅시다(`rs`는 `replicaset` 의 약자입니다).

```shell
$ k delete po nginx-rs-dl5pz
pod "nginx-rs-dl5pz" deleted
# k get pod
NAME             READY   STATUS    RESTARTS   AGE
nginx-rs-jnkg7   1/1     Running   0          14s
nginx-rs-mddjp   1/1     Running   0          52m
nginx-rs-wr62t   1/1     Running   0          52m
```

새 파드(`nginx-rs-jnkg7`)가 바로 올라옵니다. 레플리카셋 컨트롤러가 현재 상태인, 2개의 복제본을 확인하고, 원하는 상태인 3개의 복제본으로, 컨트롤루프를 실행했습니다(reconcile). `describe` 명령의 이벤트 부분에서 확인할 수 있습니다.&#x20;

```shell
$ k describe rs nginx-rs  | grep -A10 Events
Events:
  Type    Reason            Age    From                   Message
  ----    ------            ----   ----                   -------
  Normal  SuccessfulCreate  55m    replicaset-controller  Created pod: nginx-rs-mddjp
  Normal  SuccessfulCreate  55m    replicaset-controller  Created pod: nginx-rs-dl5pz
  Normal  SuccessfulCreate  55m    replicaset-controller  Created pod: nginx-rs-wr62t
  Normal  SuccessfulCreate  3m55s  replicaset-controller  Created pod: nginx-rs-jnkg7
```

### 스케일 업/다운

레플리카셋의 복제본을 스케일 업 또는 다운할 수 있습니다.

```shell
# Scale up
$ k scale rs nginx-rs --replicas 5
replicaset.apps/nginx-rs scaled
$ k get rs nginx-rs
NAME       DESIRED   CURRENT   READY   AGE
nginx-rs   5         5         3       6h15m
$ k get pods -l app=nginx
NAME             READY   STATUS              RESTARTS   AGE
nginx-rs-ckkvw   0/1     ContainerCreating   0          16s
nginx-rs-jnkg7   1/1     Running             0          5h23m
nginx-rs-mddjp   1/1     Running             0          6h15m
nginx-rs-wr62t   1/1     Running             0          6h15m
nginx-rs-zsnlv   0/1     ContainerCreating   0          16s

# Scale down
$ k scale rs nginx-rs --replicas 1
replicaset.apps/nginx-rs scaled
$ k get rs nginx-rs
NAME       DESIRED   CURRENT   READY   AGE
nginx-rs   1         1         1       6h16m
$ k get pods -l app=nginx
NAME             READY   STATUS    RESTARTS   AGE
nginx-rs-wr62t   1/1     Running   0          6h17m
```

스케일 업/다운 시 새 파드가 생성되거나 파드가 삭제되는걸 확인할 수 있습니다. `scale` 서브 명령 대신 직접 매니페스트를 수정하거나(`edit`) 패치를 요청(`patch`)하여 스케일 업/다운 할 수도 있습니다.

실습 환경을 정리합니다.

```shell
$ k delete rs nginx-rs
replicaset.apps "nginx-rs" deleted
$ k get rs
No resources found in default namespace.
$ k get po
No resources found in default namespace.
```

레플리카셋을 지우면 워크로드인 파드 역시 삭제됩니다.

### 정리

* 대부분의 (워크로드) 객체는 `.spec.selector`를 통해 관리할 파드를 선택합니다.
* 객체가 관리할 파드의 스펙은 `.spec.template`에 명세합니다.
* ReplicaSets maintain a stable number of replicas, if the Pods it are deleted by the replicaset controller.
* 레플리카셋은 파드 복제본 안정적으로 유지하여 고가용성을 확보합니다.
* 레플리카셋은 `scale` 서브 명령이나 `.spec.replicas` 를 수정하여 스케일 업/다운이 가능합니다.

### 실습

1. `nginx` 이미지의 5개의 복제본의 레플리카셋을 만들어 보자.
2. 복제본을 10개 스케일 업 해보자.
3. 3개까지 스케일 다운 해보자.

### 참고

* [https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
