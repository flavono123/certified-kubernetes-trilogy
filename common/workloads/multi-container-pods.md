# Multi-container Pods

_파드_에선 하나 뿐만 아니라 여러 개 컨테이너를 실행할 수 있습니다(`spec.containers[]` 는 배열입니다!).

하지만 각각의 기능이 있는 여러 컨테이너를 한 파드에서 실행시키는게 목적은 아닙니다. 하나의 기능을 하는 메인 컨테이너에 부수적인 역할을 하는 **보조 컨테이너**를 실행하는게 목적입니다.

보조 컨테이너는 메인 컨테이너와 **볼륨, IP, 포트와 같은 스토리지 또는 네트워크 자원을 공유**하면서 역할을 합니다. 또 보조 컨테이너는 메인 컨테이너와 같은 파드로써 **라이프사이클을 공유**합니다.

다음은 여러 컨테이너를 사용하는 대표적인 패턴들입니다:

* 사이드카 패턴
* 어댑터 패턴
* 앰버서더 패턴

### 사이드카 패턴

메인 컨테이너의 로그를 수집하는 보조 컨테이너가 대표적인 사이드카 패턴의 멀티 컨테이너입니다.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-sidecar
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
  - name: log-sidecar
    image: busybox
    args: [/bin/sh, -c, 'tail -n+1 -f /var/log/nginx/access.log']
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
  volumes:
  - name: logs
    emptyDir: {}
```

보조 컨테이너 `log-sidecar` 는 메인 컨테이너인 `nginx` 와 볼륨을 공유하고 액세스 로그를 출력(tailiing)합니다(/var/log/nginx는 실제 액세스 로그 파일이 있는 디렉토리입니다).&#x20;

파드를 실행하고 요청을 보낸 후 보조 컨테이너의 로그를 확인하면 메인 컨테이너의 액세스 로그를 볼 수 있습니다.

```bash
# 위 매니페스트를 pod-sidecar.yaml 파일에 씀
$ k apply -f pod-sidecar.yaml
pod/nginx-sidecar created
$ k get po -owide
NAME             READY   STATUS    RESTARTS   AGE     IP            NODE     NOMINATED NODE   READINESS GATES
nginx-sidecar    2/2     Running   0          8s      172.16.1.17   node-2   <none>           <none>
$ curl 172.16.1.17
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
(...응답 생략...)
# log-sidecar의 로그 확인
$ k logs -f nginx-sidecar log-sidecar
172.16.0.0 - - [01/Dec/2022:15:19:28 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/7.68.0" "-"

```

### 어댑터 패턴

어댑터 패턴은 메인 컨테이너의 출력을 다듬는(formatting) 역할을 합니다.

예제로 간단히 현재 시각을 계속 출력하는 앱이 있습니다.

```bash
$ k run krts --image busybox --command -- sh -c 'while true; do date +"%Y/%m/%dT%T"; sleep 10; done'
pod/krts created
$ k logs -f krts
2022/12/01T16:13:13
2022/12/01T16:13:14
2022/12/01T16:13:15
2022/12/01T16:13:16
2022/12/01T16:13:17
2022/12/01T16:13:18
2022/12/01T16:13:19
2022/12/01T16:13:20
^C
```

하지만 서양식으로 _일/월/연_ 형태로 시각을 출력하는 다른 앱이 있을 때 로그 포맷을 맞추고 싶습니다. 이때 어댑터 컨테이너를 사용할 수 있습니다. 위 명령을 기반으로  템플릿을 만들어 다음 매니페스트를 적용해봅시다.

```yaml
# k run ents --image busybox --command -- sh -c 'while true; do date +"%Y/%m/%dT%T" >> /var/log/ts/log; sleep 1; done'
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: ents
  name: ents
spec:
  containers:
  - command:
    - sh
    - -c
    - while true; do date +"%d/%m/%YT%T" >> /var/log/ts.log ; sleep 1; done
    image: busybox
    name: ents
    resources: {}
    volumeMounts:
    - name: logs
      mountPath: /var/log
  - name: log-adapter
    image: busybox
    command:
    - sh
    - -c
    - tail -n+1 -f /var/log/ts.log | awk -F'[/T]' '{print $3"/"$2"/"$1"T"$4}'
    volumeMounts:
    - name: logs
      mountPath: /var/log
  volumes:
  - name: logs
    emptyDir: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

보조 컨테이너 `log-adapter` 에서 로그의 _일/월/연_ 형식을 _연/월/일_ 형식으로 바꿔줍니다(`print $3"/"$2"/"$1`). 보조 컨테이너와 로그 파일을 공유하기 위해 메인 컨테이너에서 출력을 파일에 저장하고 해당 디렉토리를 같은 볼륨으로 마운트했습니다(볼륨은 스토리지 챕터에서 자세히 다룹니다).

`ents`의 어댑터 컨테이너를 통해 `krts` 파드와 같은 포맷의 로그를 볼 수 있습니다.

```bash
$ k logs -f ents log-adapter
2022/12/01T16:25:21
2022/12/01T16:25:22
2022/12/01T16:25:23
2022/12/01T16:25:24
2022/12/01T16:26:25
2022/12/01T16:26:26
2022/12/01T16:26:27
^C
```

### 앰배서더 패턴

앰배서더 패턴은 메인 컨테이너에 서비스 프록시 역할을 하는 보조 컨테이너로 구성합니다. 보조 컨테이너는 파드의 네트워크 연결을 담당하고 메인 컨테이너가 이를 신경쓰지 않아도 되게 합니다.

(앰배서더 패턴 예제는 준비중입니다)

### 초기화 컨테이너

위 보조 컨테이너 패턴과 달리, 파드의 앱 컨테이너 실행 전 완전히 실행할 수 있는 _초기화 컨테이너(initContainers)_가 있습니다.

초기화 컨테이너는 특정 서비스나 앱의 실행을 기다리거나 앱의 구성(configurations) 또는 볼륨을 준비할 수 있습니다. 예제는 후자에 해당하는, nginx 앱의 구성을 준비하는 초기화 컨테이너입니다.

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: hostname-nginx
  name: hostname-nginx
spec:
  containers:
  - image: nginx
    name: hostname-nginx
    resources: {}
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
  initContainers:
  - image: busybox
    name: init-index
    command:
    - sh
    - -c
    - cp /etc/hostname /html/index.html
    volumeMounts:
    - name: html
      mountPath: /html
  volumes:
  - name: html
    emptyDir: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

초기화 컨테이너는 파드 `spec.initContainers` 에 선언합니다. `spec.containers` 처럼 배열이며, 명세된 순서대로 하나씩 실행됩니다.

위 예제에서 초기화 컨테이너 `init-index`는 앱 컨테이너 `nginx`와 볼륨으로 연결하여 응답 인덱스 파일을 /etc/hostname 으로 교체합니다(이렇게하면 [Networking > Services](https://flavono123.gitbook.io/certified-kubernetes-trilogy/common/networking/services)의 예제에서 사용한 [vonogoru123/nginx-hostname](https://github.com/flavono123/nginx-hostname) 컨테이너 이미지와 동작이 같아집니다).

```shell
$ k get po hostname-nginx -owide
NAME             READY   STATUS    RESTARTS   AGE   IP            NODE     NOMINATED NODE   READINESS GATES
hostname-nginx   1/1     Running   1          8d    172.16.1.25   node-2   <none>           <none>
$ curl 172.16.1.25
hostname-nginx
```

### 정리

* 한 파드에 여러 컨테이너를 명세할 수 있고, 설계 목적에 따라 앱인 메인 컨테이너를 제외하곤 다음 패턴의 보조 컨테이너로 사용된다.
  * 사이드카 패턴
  * 어댑터 패턴
  * 앰배서더 패턴
* 초기화 컨테이너는 파드의 앱 컨테이너 실행 전 실행되어 준비하는 역할을 한다.

### 실습

* 로그 수집을 하는 보조 컨테이너가 있는 사이드카 패턴의 파드를 실행해보세요.
* 로그 포맷을 표준화하는 보조 컨테이너가 있는 어댑터 패턴의 파드를 실행해보세요.
* 메인 컨테이너와 공유 볼륨에서 디렉토리를 준비하는 초기화 컨테이너가 있는 파드를 실행해보세요.

### 참고

* [https://kubernetes.io/ko/docs/concepts/workloads/pods/](https://kubernetes.io/ko/docs/concepts/workloads/pods/)
* [https://seongjin.me/kubernetes-multi-container-pod-design-patterns/](https://seongjin.me/kubernetes-multi-container-pod-design-patterns/)
* [https://www.weave.works/blog/kubernetes-patterns-the-ambassador-pattern](https://www.weave.works/blog/kubernetes-patterns-the-ambassador-pattern)
