# StatefulSets

스테이트풀셋(`StatefulSet`)은 Kubernetes에서 상태가 있는 애플리케이션을 배포하기 위한 워크로드 객체입니다. 스테이트풀셋은 각 파드에 고유한 이름을 부여하고 상태가 있는 애플리케이션을 배포할 수 있도록 합니다.

다음 요구사항 중 하나라도 해당되면 스테이트풀셋을 사용할 수 있습니다:
- 고유한(unique) 네트워크 식별자
- 지속성(persistant) 스토리지
- 순차적인(ordered) 배포, 스케일링 그리고 롤링 업데이트.

마지막 요구사항인 순차적인 배포, 스케일링 그리고 롤링 업데이트에 대해서 알아보겠습니다.

## StatefulSet 생성

다음은 스테이트풀셋을 생성하는 YAML 파일의 예입니다.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx
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

디플로이먼트와 매우 유사합니다. 스테이트풀셋은 `kubectl create` 명령만으로 만들 수 없기 때문에, 디플로이먼트를 만든 후 `kind`를 `StatefulSet`으로 변경해 매니페스트를 생성할 수도 있습니다.

위 스테이트풀셋을 만들면서 파드 생성을 모니터링하겠습니다.

```sh
# 다른 터미널에서 실행
$ k get po -w -l app=nginx
NAME      READY   STATUS    RESTARTS   AGE
nginx-0   0/1     Pending   0          0s
nginx-0   0/1     ContainerCreating   0          0s
nginx-0   1/1     Running             0          3s
nginx-1   0/1     Pending             0          0s
nginx-1   0/1     ContainerCreating   0          0s
nginx-1   1/1     Running             0          9s
nginx-2   0/1     Pending             0          0s
nginx-2   0/1     ContainerCreating   0          0s
nginx-2   1/1     Running             0          3s
```

스테이트풀셋은 파드가 생성되는 순서대로 뒤에 순번이 붙습니다. 디플로이먼트가 해시를 붙이는 것과 다릅니다. 또한 스테이트풀셋은 파드를 생성할 때 순서대로 생성합니다. 앞선 순번의 파드가 Ready가 되어야 다음 파드를 생성합니다. 반면 디플로이먼트는 랜덤하게 생성합니다.

## StatefulSet 스케일링

스테이트풀셋 레플리카를 5로 변경해보겠습니다.

```sh
$ k scale sts nginx --replicas=5
```

```sh
# 다른 터미널에서 실행
$ k get po -w -l app=nginx
nginx-3   0/1     Pending   0             0s
nginx-3   0/1     Pending   0             0s
nginx-3   0/1     ContainerCreating   0             0s
nginx-3   0/1     ContainerCreating   0             0s
nginx-3   1/1     Running             0             2s
nginx-4   0/1     Pending             0             0s
nginx-4   0/1     Pending             0             0s
nginx-4   0/1     ContainerCreating   0             0s
nginx-4   0/1     ContainerCreating   0             1s
nginx-4   1/1     Running             0             3s
```

`nginx-3`, `nginx-4`가 순서대로 생성됩니다. 스테이트풀셋은 스케일 아웃 시 새 파드가 뒤에서부터 순서대로 생성됩니다.

이번엔 레플리카를 2로 줄여보겠습니다.

```sh
$ k scale sts nginx --replicas=2
```

```sh
# 다른 터미널에서 실행
$ k get po -w -l app=nginx
nginx-4   1/1     Terminating         0             84s
nginx-4   1/1     Terminating         0             85s
nginx-4   0/1     Terminating         0             85s
nginx-4   0/1     Terminating         0             85s
nginx-4   0/1     Terminating         0             85s
nginx-3   1/1     Terminating         0             87s
nginx-3   1/1     Terminating         0             88s
nginx-3   0/1     Terminating         0             89s
nginx-3   0/1     Terminating         0             89s
nginx-3   0/1     Terminating         0             89s
nginx-2   1/1     Terminating         0             7m9s
nginx-2   1/1     Terminating         0             7m9s
nginx-2   0/1     Terminating         0             7m9s
nginx-2   0/1     Terminating         0             7m9s
nginx-2   0/1     Terminating         0             7m9s
```

`nginx-4`, `nginx-3`, `nginx-2` 가 순서대로, 생성된 순번의 역순으로 삭제됩니다. 스테이트풀셋은 스케일 인 시 뒤에서부터 역순으로 삭제됩니다.

## StatefulSet 업데이트

스테이트풀셋의 파드 컨테이너 이미지를 `nginx:1.19.2`로 변경해보겠습니다. 변경을 확실히 확인하기 위해 레플리카를 3으로 만들고 업데이트를 진행하겠습니다.

```sh
$ k scale sts nginx --replicas=3
$ k set image sts nginx nginx=nginx:1.19.2
```

```sh
# 다른 터미널에서 실행
$ k get po -w -l app=nginx
nginx-2   0/1     ContainerCreating   0             0s
nginx-2   0/1     ContainerCreating   0             1s
nginx-2   1/1     Running             0             3s
nginx-2   1/1     Terminating         0             82s
nginx-2   1/1     Terminating         0             83s
nginx-2   0/1     Terminating         0             83s
nginx-2   0/1     Terminating         0             83s
nginx-2   0/1     Terminating         0             83s
nginx-2   0/1     Pending             0             0s
nginx-2   0/1     Pending             0             0s
nginx-2   0/1     ContainerCreating   0             1s
nginx-2   0/1     ContainerCreating   0             1s
nginx-2   1/1     Running             0             9s
nginx-1   1/1     Terminating         0             14m
nginx-1   1/1     Terminating         0             14m
nginx-1   0/1     Terminating         0             14m
nginx-1   0/1     Terminating         0             14m
nginx-1   0/1     Terminating         0             14m
nginx-1   0/1     Pending             0             0s
nginx-1   0/1     Pending             0             0s
nginx-1   0/1     ContainerCreating   0             0s
nginx-1   0/1     ContainerCreating   0             1s
nginx-1   1/1     Running             0             10s
nginx-0   1/1     Terminating         0             14m
nginx-0   1/1     Terminating         0             14m
nginx-0   0/1     Terminating         0             14m
nginx-0   0/1     Terminating         0             14m
nginx-0   0/1     Terminating         0             14m
nginx-0   0/1     Pending             0             0s
nginx-0   0/1     Pending             0             0s
nginx-0   0/1     ContainerCreating   0             0s
nginx-0   0/1     ContainerCreating   0             1s
nginx-0   1/1     Running             0             3s
```

스테이트풀셋의 업데이트 시 파드는 뒤에서부터 역순으로 업데이트 합니다.

<details>
<summary>Q1. 다음 스테이트풀셋을 생성하세요.
<br> - 이름: <code>web</code>
<br> - 레플리카: <code>3</code>
<br> - 이미지: <code>nginx</code>
</summary>

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx
```
</details>

<details>
<summary>Q2. <code>web</code> 스테이트풀셋의 업데이트 전략을 확인하고 <code>OnDelete</code>로 바꿔보세요.</summary>

```sh
$ k get sts web -oyaml | yq .spec.updateStrategy
rollingUpdate:
  partition: 0
type: RollingUpdate
```

```yaml
# k edit sts web
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
...
  updateStrategy:
    type: OnDelete # 수정
...
```

</details>

<details>
<summary>Q3. <code>web</code> 스테이트풀셋의 업데이트 전략을 다시 <code>RollingUpdate</code>로 바꾸고 파드를 재시작 해보세요(파드 모니터)</summary>

```sh
$ k rollout restart sts web
```

```sh
# 다른 터미널에서 실행
$ k get po -w
```

</details>

<details>
<summary>Q4. <code>web</code> 스테이트풀셋의 레플리카를 5로 변경해보세요(파드 모니터).</summary>

```sh
$ k scale sts web --replicas=5
```

```sh
# 다른 터미널에서 실행
$ k get po -w
```

</details>
