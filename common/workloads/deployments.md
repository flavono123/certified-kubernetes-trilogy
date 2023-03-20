# Deployments

_디플로이먼트_(_Deployments_) 레플리카셋을 사용하여 파드를 업데이트 할 수 있습니다.

디플로이먼트를 하나 만들어 봅시다.

```shell
$ k create deploy nginx --image=nginx:1.20.1 --replicas=3
deployment.apps/nginx created
$ k get rs
NAME               DESIRED   CURRENT   READY   AGE
nginx-5549ffcf5f   3         3         3       3s
$ k get po
NAME                     READY   STATUS    RESTARTS   AGE
nginx-5549ffcf5f-ktp8p   1/1     Running   0          8s
nginx-5549ffcf5f-sggxc   1/1     Running   0          8s
nginx-5549ffcf5f-x9zbq   1/1     Running   0          8s
```

레플리카셋과 달리, 디플로이먼트는 명령형 생성 방법인 `create` 서브 명령을 지원합니다. 파드 생성과(`run`) 마찬가지로`--image` 는 필수 플래그이고 `--replicas` 는 아닙니다(기본 값 1).

디플로이먼트를 생성하면 레플리카셋도 생성됩니다. 레플리카셋 이름은 디플로이먼트 이름에 10자리 16진수 글자 접미사([pod-template-hash](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#pod-template-hash-label))가 붙어 있습니다.

```shell
$ k get deploy nginx -oyaml | yq .spec
progressDeadlineSeconds: 600
replicas: 3
revisionHistoryLimit: 10
selector:
  matchLabels:
    app: nginx
strategy:
  rollingUpdate:
    maxSurge: 25%
    maxUnavailable: 25%
  type: RollingUpdate
template:
  metadata:
    creationTimestamp: null
    labels:
      app: nginx
  spec:
    containers:
      - image: nginx:1.20.1
        imagePullPolicy: IfNotPresent
        name: nginx
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
    dnsPolicy: ClusterFirst
    restartPolicy: Always
    schedulerName: default-scheduler
    securityContext: {}
    terminationGracePeriodSeconds: 30
```

디플로이먼트 스펙은 레플리카 셋과 비슷합니다.

* `.spec.selector` : 파드 셀렉터
* `.spec.replica` : 파드 복제본 수
* `.spec.template` : 파드 스펙

다른 곳은 업데이트를 위한 필드가 있습니다(`.spec.strategy`).

### 디플로이먼트로 파드 업데이트하기

다음 명령으로 파드 이미지를 새 버전인 `nginx:1.22.1`으로 업데이트 할 수 있습니다. 업데이트가 어떻게 되는지 보기 위해, 다른 프롬프트 몇 개를 열어 `watch` 명령으로 살펴봅니다.

```shell
# k set image deploy <deploymentname> <podname>=<image>
$ k set image deploy nginx nginx=nginx:1.22.1
deployment.apps/nginx image updated
```

```shell
# Watching prompt 1 - Pods
$ k get po -w
```

NAME READY STATUS RESTARTS AGE\
<mark style="color:blue;">nginx-5549ffcf5f-ktp8p 1/1 Running 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-sggxc 1/1 Running 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-x9zbq 1/1 Running 0 27m</mark>\
<mark style="color:green;">nginx-58cf58dc6f-j686m 0/1 Pending 0 0s</mark>\ <mark style="color:green;">nginx-58cf58dc6f-j686m 0/1 Pending 0 0s</mark>\ <mark style="color:green;">nginx-58cf58dc6f-j686m 0/1 ContainerCreating 0 0s</mark>\ <mark style="color:green;">nginx-58cf58dc6f-j686m 0/1 ContainerCreating 0 0s</mark>\ <mark style="color:green;">nginx-58cf58dc6f-j686m 1/1 Running 0 2s</mark>\
<mark style="color:blue;">nginx-5549ffcf5f-ktp8p 1/1 Terminating 0 27m</mark>\
<mark style="color:green;">nginx-58cf58dc6f-6vdzq 0/1 Pending 0 0s</mark>\ <mark style="color:green;">nginx-58cf58dc6f-6vdzq 0/1 Pending 0 0s</mark>\ <mark style="color:green;">nginx-58cf58dc6f-6vdzq 0/1 ContainerCreating 0 0s</mark>\
<mark style="color:blue;">nginx-5549ffcf5f-ktp8p 1/1 Terminating 0 27m</mark>\
<mark style="color:green;">nginx-58cf58dc6f-6vdzq 0/1 ContainerCreating 0 1s</mark>\
<mark style="color:blue;">nginx-5549ffcf5f-ktp8p 0/1 Terminating 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-ktp8p 0/1 Terminating 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-ktp8p 0/1 Terminating 0 27m</mark>\
<mark style="color:green;">nginx-58cf58dc6f-6vdzq 1/1 Running 0 2s</mark>\
<mark style="color:blue;">nginx-5549ffcf5f-x9zbq 1/1 Terminating 0 27m</mark>\
<mark style="color:green;">nginx-58cf58dc6f-llrh7 0/1 Pending 0 0s</mark>\ <mark style="color:green;">nginx-58cf58dc6f-llrh7 0/1 Pending 0 0s</mark>\ <mark style="color:green;">nginx-58cf58dc6f-llrh7 0/1 ContainerCreating 0 0s</mark>\
<mark style="color:blue;">nginx-5549ffcf5f-x9zbq 1/1 Terminating 0 27m</mark>\
<mark style="color:green;">nginx-58cf58dc6f-llrh7 0/1 ContainerCreating 0 1s</mark>\ <mark style="color:green;">nginx-58cf58dc6f-llrh7 1/1 Running 0 2s</mark>\
<mark style="color:blue;">nginx-5549ffcf5f-sggxc 1/1 Terminating 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-x9zbq 0/1 Terminating 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-x9zbq 0/1 Terminating 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-x9zbq 0/1 Terminating 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-sggxc 1/1 Terminating 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-sggxc 0/1 Terminating 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-sggxc 0/1 Terminating 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-sggxc 0/1 Terminating 0 27m</mark>\ <mark style="color:blue;">nginx-5549ffcf5f-sggxc 0/1 Terminating 0 27m</mark>

```bash
# Watch prompt 2 - ReplicaSets
k get rs -w
```

NAME DESIRED CURRENT READY AGE\ <mark style="color:blue;">nginx-5549ffcf5f 3 3 3 27m</mark>\
<mark style="color:green;">nginx-58cf58dc6f 1 0 0 0s</mark>\ <mark style="color:green;">nginx-58cf58dc6f 1 0 0 0s</mark>\ <mark style="color:green;">nginx-58cf58dc6f 1 1 0 0s</mark> \ <mark style="color:green;">nginx-58cf58dc6f 1 1 1 2s</mark> \
<mark style="color:blue;">nginx-5549ffcf5f 2 3 3 27m</mark> \
<mark style="color:green;">nginx-58cf58dc6f 2 1 1 2s</mark> \
<mark style="color:blue;">nginx-5549ffcf5f 2 3 3 27m</mark> \
<mark style="color:green;">nginx-58cf58dc6f 2 1 1 2s</mark> \
<mark style="color:blue;">nginx-5549ffcf5f 2 2 2 27m</mark> \
<mark style="color:green;">nginx-58cf58dc6f 2 2 1 2s</mark> \
<mark style="color:green;">nginx-58cf58dc6f 2 2 2 4s</mark> \
<mark style="color:blue;">nginx-5549ffcf5f 1 2 2 27m</mark> \ <mark style="color:blue;">nginx-5549ffcf5f 1 2 2 27m</mark> \ <mark style="color:blue;">nginx-5549ffcf5f 1 1 1 27m</mark> \
<mark style="color:green;">nginx-58cf58dc6f 3 2 2 4s</mark> \ <mark style="color:green;">nginx-58cf58dc6f 3 2 2 4s</mark> \ <mark style="color:green;">nginx-58cf58dc6f 3 3 2 4s</mark> \ <mark style="color:green;">nginx-58cf58dc6f 3 3 3 6s</mark> \
<mark style="color:blue;">nginx-5549ffcf5f 0 1 1 27m</mark> \ <mark style="color:blue;">nginx-5549ffcf5f 0 1 1 27m</mark> \ <mark style="color:blue;">nginx-5549ffcf5f 0 0 0 27m</mark>

```shell
# Watch prompt 3 - Rollout status
$ k rollout status deploy nginx
Waiting for deployment "nginx" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx" rollout to finish: 1 old replicas are pending termination...
deployment "nginx" successfully rolled out

```

출력을 잘 보기 위해 코드 블럭 바깥으로 꺼냈습니다. 파드와 레플리카셋 업데이트 <mark style="color:green;">전</mark>과 <mark style="color:blue;">후</mark>를 색칠했습니다.

어떻게 업데이트 된건지 보이시나요? <mark style="color:green;">새 파드</mark>는 <mark style="color:blue;">예전 것</mark>이 하나씩 죽으면 하나씩 올라옵니다. 이렇게 디플로이먼트는 복제본 3개를 유지합니다. 이것이 디플로이먼트의 기본 업데이트 전략인 롤링 업데이트입니다.&#x20;

왜 한번에 교체되는 파드는 한개일까요? 롤링 업데이트 전략에(`.spec.strategy.rollingUpdate`) 명세된 `maxSurge` 와 `maxUnavailable` 때문에 그렇습니다. 각각 최대로 늘어날 수 있거나 줄어들 수 있는 파드 복제본의 개수 또는 퍼센트를 뜻하고, 기본 값은 25%로 같습니다(3 \* 0.75 =\~ 1).

롤링 업데이트 외에, 모든 파드를 일시에 죽이고 다시 시작하는 `Recreate` 이라는 디플로이먼트 전략도 있습니다.

### 롤백

`rollout history` 명령으로 디플로이먼트의 리비전을 확인할 수 있습니다.

```
$ k rollout history deploy nginx
deployment.apps/nginx
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

리비전 1은 업데이트 이전 `nginx:1.20.1` 이미지의 레플리카셋이고, 리비전 2는 `nginx:1.22.1`의 레플리카셋입니다.

`rollout undo` 명령으로 이전 리비전의 레플리카셋으로 롤백할 수 있습니다.

```shell
$ k rollout undo deploy nginx
deployment.apps/nginx rolled back
$ k rollout history deploy nginx
deployment.apps/nginx
REVISION  CHANGE-CAUSE
2         <none>
3         <none>

$ k get po nginx-5549ffcf5f-2p7jq -oyaml | yq .spec.containers[].image
nginx:1.20.1
```

리비전 1이 아니라 새 리비전 3이 만들어졌습니다. 이전 레플리카셋으로 롤백하더라도 리비전은 새로 만들게 됩니다.

레플리카셋처럼, 디플로이먼트도 `scale` 명령 또는 `.spec.replicas` 를 수정하거나 패치하여 스케일 업/다운이 가능합니다.

실습 환경을 정리합니다. 디플로이먼트를 삭제하면 관련된 파드, 레플리카셋이 같이 삭제됩니다.

```shell
$ k delete deploy nginx
deployment.apps "nginx" deleted
$ k get deploy,rs,po
No resources found in default namespace.
```

### 정리

* 디플로이먼트는 레플리카셋으로 파드를 업데이트 한다.
* `rollout status` 로 디플로이먼트 업데이트 상태를 확인할 수 있다.
* `rollout history` 명령으로 리비전 목록을 볼 수 있습니다.
* `set image` 명령으로 파드 이미지를 바꿔 디플로이먼트를 업데이트 할 수 있다.
* `rollout undo` 로 이전 레플리카셋으로 롤백할 수 있습니다.
* `-w/--watch` 플래그로 객체가 실시간으로 변하는 것을 확인할 수 있습니다.

### 실습

1. `nginx:1.23.2` 이미지, 복제본(replicas) 5개의 디플로이먼트를 생성하세요.
2. 복제본을 10개까지 스케일 업 하세요.
3. 이미지를 `nginx:1.21.6` 으로 업데이트 하세요.
4. 롤링 업데이트(rollingUpdate) 시 한 번에 교체되는 파드가 2개가 되도록 `maxSurge` , `maxUnavailable` 을 수정하세요.
5. 업데이트 전략을 `Recreate`으로 바꿔 보세요.
6. 이전 레플리카셋으로 롤백해보세요.

### 참고

* [https://kubernetes.io/docs/concepts/workloads/controllers/deployment/](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
