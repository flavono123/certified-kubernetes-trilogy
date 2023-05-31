# Readiness, Liveness Probes

## Readiness Probes
레디니스 프로브는 파드의 컨테이너마다 지정하여 파드 준비성(Readiness)을 나타냅니다. 파드 준비성은 파드가 서비스 요청을 처리할 준비가 되었는지를 나타냅니다. 파드가 준비되지 않은 상태에서 서비스 요청이 들어오면, 해당 파드는 서비스의 엔드포인트 목록에 포함되지 않습니다. 파드가 준비된 상태가 되면, 서비스의 엔드포인트 목록에 포함되어 서비스 요청을 처리할 수 있게 됩니다.

레디니스 프로브가 지정되지 않은 컨테이너는 실행(Running) 후 바로 준비된 상태가 됩니다. 하지만 컨테이너가 실행되더라도 실제론 요청을 처리할 수 없는 앱들도 있습니다. 예를 들어, 앱이 초기화를 시간이 필요하거나 DB 연결이 필요한 경우가 있을 수 있습니다.

레디니스 프로브를 포함하여 프로브엔 확인 메커니즘이 세가지 있습니다:
- Exec: 컨테이너 내부에서 명령어를 실행하고, 명령어의 종료 코드가 0이면 성공, 0이 아니면 실패로 간주합니다.
- TCPSocket: 컨테이너 내부에서 지정한 포트로 TCP 연결을 시도하고, 연결이 성공하면 성공, 실패하면 실패로 간주합니다.
- HTTPGet: 컨테이너 내부에서 지정한 URL로 HTTP GET 요청을 시도하고, 응답 코드가 200~399 사이면 성공, 그 외의 코드면 실패로 간주합니다.

간단하게 exec으로 레디니스 프로브를 지정해보겠습니다:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-exec-pod
  labels:
    app: readiness-exec-pod
spec:
  containers:
  - name: readiness-exec-container
    image: busybox
    args:
    - /bin/sh
    - -c
    - sleep 30; touch /tmp/healthy; sleep 3000
    readinessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: readiness-exec-pod
  name: readiness-exec-pod
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: readiness-exec-pod
```
레디니스 프로브는 5초 후에 시작되고(`initialDelaySeconds`), 5초마다 실행됩니다(`periodSeconds`). 컨테이너 내부에서 /tmp/healthy 파일을 읽을 수 있으면(`cat /tmp/healthy`) 성공, 그렇지 않으면 실패로 간주합니다. 따라서 이 파드는 약 30초 후에 준비된 상태가 될 것입니다.

```sh
$ k get po -w -l app=readiness-exec-pod
NAME                 READY   STATUS              RESTARTS   AGE
readiness-exec-pod   0/1     ContainerCreating   0          0s
readiness-exec-pod   0/1     Running             0          5s
readiness-exec-pod   1/1     Running             0          35s
```

또 노출한 서비스의 엔드포인트 역시 레디니스 프로브가 성공한 후에 생기는 것을 확인할 수 있습니다:
```sh
$ k describe svc readiness-exec-pod  | grep -i endpoints
Endpoints:         <none>

$ k get ep readiness-exec-pod
NAME                 ENDPOINTS   AGE
readiness-exec-pod   <none>      9s

# 30초 후

$ k describe svc readiness-exec-pod  | grep -i endpoints
Endpoints:         172.16.5.12:8080

$ k get ep readiness-exec-pod
NAME                 ENDPOINTS          AGE
readiness-exec-pod   172.16.5.12:8080   40s
```

## Liveness Probes
리브니스 프로브는 파드의 컨테이너마다 지정하여 각 컨테이너의 활성(Liveness)을 나타냅니다. 만약 프로브가 실패하면 해당 컨테이너는 재시작됩니다. 리브니스 프로브가 따로 지정되어 있지 않다면 컨테이너 프로세스가 정상 실행이 아닐 때 파드의 재시작 정책(`restartPolicy`)에 따라 재시작됩니다.

따라서 보통은 리브니스 프로브를 지정하지 않아도 되지만 컨테이너의 재시작 조건을 특정할 때 레디니스 프로브를 사용합니다. 예를 들어, 데드락이 발생한다면 컨테이너 프로세스는 실행 중이지만 hang 상태일 것이기 때문에 리브니스 프로브를 지정하여 재시작할 수 있습니다.

리브니스 프로브도 레디니스 프로브와 마찬가지로 세가지 확인 메커니즘과 시간 옵션을 사용합니다:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-exec-pod
  labels:
    app: liveness-exec-pod
spec:
  containers:
  - name: liveness-exec-container
    image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 3000
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

레디니스 프로브와 같게 정의했지만, 컨테이너에서 30초 후에 /tmp/healthy 파일을 제거하기 때문에 30초 후에 컨테이너가 재시작 될 것입니다. 이 내용은 `describe`의 이벤트를 통해 더 잘 확인할 수 있습니다:

```sh
$ k describe po liveness-exec-pod
...
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  67s                default-scheduler  Successfully assigned default/liveness-exec-pod to node-2
  Normal   Pulling    66s                kubelet            Pulling image "busybox"
  Normal   Pulled     65s                kubelet            Successfully pulled image "busybox" in 1.41057559s (1.410590099s including waiting)
  Normal   Created    65s                kubelet            Created container liveness-exec-container
  Normal   Started    65s                kubelet            Started container liveness-exec-container
  Warning  Unhealthy  22s (x3 over 32s)  kubelet            Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
  Normal   Killing    22s                kubelet            Container liveness-exec-container failed liveness probe, will be restarted
```
