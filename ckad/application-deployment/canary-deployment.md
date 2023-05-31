# Canary Deployments

카나리 배포는 새로운 버전의 애플리케이션을 일부 사용자에게 먼저 배포하고, 이후에 전체 사용자에게 배포하는 전략입니다. 이번에도 이전 버전의 애플리케이션을 '블루', 새로운 버전의 애플리케이션을 '그린'의 각각 워크로드를 설치하고 그 비율과 공통 서비스를 이용하여 카나리 배포를 구현해보겠습니다.

블루/그린 워크로드를 먼저 배포합니다:

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-blue
  labels:
    app: web
    version: blue
spec:
  replicas: 10
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
---
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-green
  labels:
    app: web
    version: green
spec:
  replicas: 0
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

그린 워크로드 레플리카는 0으로 배포하여 아직 애플리케이션 업그레이드가 되지 않을 상황을 가정합니다.

다음은 블루/그린 워크로드 모두를 노출하는 서비스를 만듭니다:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
  - name: http
    port: 80
    targetPort: 8080
```

`app=web` 레이블 셀렉터가 블루/그린 두 워크로드의 파드 모두를 선택하지만, 현재 파드의 비율은 10:0 즉, 블루 파드만 100%이기 때문에 응답은 블루 애플리케이션만 하게 됩니다:

```sh
$ k run req -it --rm --image bash --restart=Never -- sh
# bash 컨테이너 내부 쉘
$ while true; do wget -qO- http://web; done
BlueBlueBlueBlueBlueBlue^C

$
blue_cnt=0
green_cnt=0
for i in $(seq 1 100); do
  res=$(wget -qO- http://web)
  if [ "$res" = 'Blue' ]; then
    blue_cnt=$((blue_cnt+1))
  elif [ "$res" = 'Green' ]; then
    green_cnt=$((green_cnt+1))
  fi
done

echo "Blue: ${blue_cnt}, Green: ${green_cnt}"
Blue: 100, Green: 0

```

그린 워크로드 레플리카를 3으로 늘리고 블루 워크로드 레플리카를 7로 줄여서 3:7 비율로 카나리 배포를 진행합니다:

```sh
$ k scale rs web-green --replicas=3
$ k scale rs web-blue --replicas=7
```

충분히 요청을 많이 해보면, 서비스가 엔드포인트에 대해 라운드로빈 방식으로 라우팅하기 때문에, 응답 비율이 배포한 파드 수에 수렴합니다.

```sh
$ k run req -it --rm --image bash --restart=Never -- sh
# bash 컨테이너 내부 쉘
$
blue_cnt=0
green_cnt=0
for i in $(seq 1 100); do
  res=$(wget -qO- http://web)
  if [ "$res" = 'Blue' ]; then
    blue_cnt=$((blue_cnt+1))
  elif [ "$res" = 'Green' ]; then
    green_cnt=$((green_cnt+1))
  fi
done

echo "Blue: ${blue_cnt}, Green: ${green_cnt}"

Blue: 77, Green: 23
```

이렇게 점진적으로 또는 원하는 비율로 각 워크로드 파드 수를 조절하여 카나리 배포를 마칠 수 있습니다. 롤백 역시 마찬가지입니다.

```sh
$ k scale rs web-green --replicas=10
$ k scale rs web-blue --replicas=0
# 롤백
$ k scale rs web-green --replicas=5
$ k scale rs web-blue --replicas=5
$ k scale rs web-green --replicas=0
$ k scale rs web-blue --replicas=10
```

두 워크로드 셋의 레플리카 개수를 조절하여 아주 간단한 카나리 배포를 구현해보았습니다. 하지만 이렇게 레플리카 수를 조정하는 방법은 원하는 배포 비율의 정밀도를 맞추기 위해 너무 많은 파드가 필요할 수도 있게 됩니다. 예를 들어 1%의 비율만 배포하려면 최소 100개의 파드가 필요합니다.


<details>
<summary>

Q1. 다음 요구사항에 맞게 6:4 비율로 카나리 배포를 구현하세요.
<br> 1. 공통
<br>   - 레이블: `app=nginx`
<br>   - 서비스 이름: `nginx`
<br>   - 서비스 포트: `80`
<br> 2. 블루
<br>   - 객체: `Deployment`
<br>   - 컨테이너 이미지: `nginx:1.14.2`
<br> 3. 그린
<br>   - 객체: `Deployment`
<br>   - 컨테이너 이미지: `nginx:1.15.12`
</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-old
  labels:
    app: nginx
spec:
  replicas: 6 # 또는 3
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
        image: nginx:1.14.2
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-new
  labels:
    app: nginx
spec:
  replicas: 4 # 또는 2
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
        image: nginx:1.15.12
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
```

</details>
