# Blue/Green Deployment

블루/그린 디플로이먼트는 애플리케이션 업그레이드 전략 중 하나입니다. 이전 버전(블루)의 애플리케이션을 그대로 유지하면서 새로운 버전(그린)의 애플리케이션을 배포하고, 테스트가 완료되면 블루 애플리케이션을 그린 애플리케이션으로 전환하는 방식입니다.

블루/그린 디플로이먼트는 다운타임이 없고 롤백이 쉽습니다. 쿠버네티스 디플로이먼트 객체의 `Recreate` 전략과 비교했을 때 그 장점이 두드러집니다. `Recreate`으로 업그레이드를 하면 이전 버전의 파드를 종료시키고 새 버전의 파드를 시작하기 때문에 그동안 애플리케이션이 중단됩니다(다운타임). 롤백 시에도 마찬가지이며 블루/그린 디플로이먼트는 이런 문제를 해결합니다.

블루/그린 디플로이먼트 전략이 `Deployment`의 `spec.strategy.type` 필드 중 하나는 아닙니다. 블루/그린 디플로이먼트는 블루와 그린 두 워크로드 셋과 서비스 그리고 레이블 셀렉터를 이용하여 구현합니다.

먼저 블루 워크로드셋을, 레플리카셋으로, 만들겠습니다:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-blue
  labels:
    app: web
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      version: blue
  template:
    metadata:
      labels:
        app: web
        version: blue
    spec:
      containers:
      - name: web
        image: vonogoru123/custom-response-server
        env:
        - name: RESPONSE
          value: "Blue"
```

`vonogoru123/custom-response-server` 이미지는 루트 경로(`/`) 요청 시 간단하게 응답하는 웹 서버입니다. `RESPONSE` 환경 변수를 통해 응답을 커스터마이즈할 수 있어서 블루와 그린 애플리케이션을 구분하기 위해 사용했습니다. 두 워크로드셋 공통 레이블 `app=web`과 블루/그린 디플로이먼트 시 이전 버전을 특정하는 `version=blue` 레이블을 추가했습니다. 이제 그린 워크로드셋을 만들겠습니다:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-green
  labels:
    app: web
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      version: green
  template:
    metadata:
      labels:
        app: web
        version: green
    spec:
      containers:
      - name: web
        image: vonogoru123/custom-response-server
        env:
        - name: RESPONSE
          value: "Green"
```

`version=green` 레이블과 환경변수 `RESPONSE=Green`를 제외하곤 블루 워크로드셋과 동일합니다. 이제 두 워크로드를 노출할 서비스를 만들겠습니다:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
    version: blue
  ports:
  - name: http
    port: 80
    targetPort: 8080
```

`app=web` 레이블 셀렉터는 블루/그린 워크로드 모두를 선택하지만, `version=blue` 레이블 셀렉터는 블루 워크로드셋만 선택합니다. 따라서 이 `web` 서비스로 요청은 모두 블루 워크로드셋으로 전달됩니다.

```sh
$ k run req --image busybox -it --rm --restart Never -- sh
# busybox 내부 쉘
/ # while true; do wget http://web; sleep 1; done
BlueBlueBlueBlueBlueBlue
```

블루/그린 디플로이먼트를 구현하기 위헤 다른 쉘에서 `web` 서비스의 레이블 셀렉터를 변경합니다:

```sh
$ k patch svc web -p '{"spec":{"selector":{"version":"green"}}}'
# 또는 k edit svc web
```

```sh
/ # while true; do wget http://web; sleep 1; done
BlueBlueBlueBlueBlueBlueBlueBlueBlueBlueBlueBlueGreenGreen
```

그린 워크로드가 이미 실행 중이기 때문에 다운타임 없이 업그레이드가 됐습니다. 롤백 역시 마찬가지입니다.

```sh
$ k patch svc web -p '{"spec":{"selector":{"version":"blue"}}}'
# 또는 k edit svc web
```

```sh
/ # while true; do wget http://web; sleep 1; done
BlueBlueBlueBlueBlueBlueBlueBlueBlueBlueBlueBlueGreenGreenGreenGreenGreenGreenBlueBlueBlueBlueBlueBlue
```

블루/그린 디플로이먼트는 두 워크로드셋을 모두 유지해야하기 때문에 업그레이드 동안 리소스가 두배로 필요하다는 단점이 있습니다.


<details>
<summary>

Q1. 다음 블루/그린 디플로이먼트를 위한 워크로드와 서비스를 생성하세요.
<br> 1. 공통
<br>   - 레이블: `app=nginx`
<br>   - 서비스 이름: `nginx`
<br>   - 서비스 포트: `80`
<br> 2. 블루
<br>   - 객체: `Deployment`
<br>   - 컨테이너 이미지: `nginx:1.14.2`
<br>   - 레이블: `deploy=old`
<br>   - 레플리카: `2`
<br> 3. 그린
<br>   - 객체: `Deployment`
<br>   - 컨테이너 이미지: `nginx:1.15.12`
<br>   - 레이블: `deploy=new`
<br>   - 레플리카: `3`
</summary>

```sh
$ k create deploy nginx-blue --image nginx:1.14.2 --replicas 2
$ k label deploy nginx-blue deploy=old
$ k create deploy nginx-green --image nginx:1.15.12 --replicas 3
$ k label deploy nginx-green deploy=new
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
    deploy: old
  ports:
  - name: http
    port: 80
    targetPort: 80
```

```sh
# 업그레이드
$ k patch svc nginx -p '{"spec":{"selector":{"deploy":"new"}}}'
# 롤백
$ k patch svc nginx -p '{"spec":{"selector":{"deploy":"old"}}}'
```

</details>
