# Log and Monitoring

쿠버네티스 파드에 문제가 있는지 확인할 수 있는 로그와 모니터링 방법에 대해 알아봅니다.
### 파드 로그 확인
`kubectl logs` 명령어를 사용하여 파드에서 실행 중인 컨테이너의 로그를 확인할 수 있습니다. 예를 들어 오류를 발생하는 다음 파드를 생성합니다:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wrongpod
  namespace: default
spec:
  containers:
    - name: wrongpod
      image: busybox
      command:
        - "sh"
        - "-c"
        - "while true; do ls /nonexistent; sleep 10;done" # 없는 경로를 확인하여 오류 발생
```

```sh
$ k logs wrongpod
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
```

`logs` 명령에 주요한 옵션들은 다음과 같습니다.
- `-f`: 파드의 로그를 실시간으로 출력
- `-p`: 파드의 이전 인스턴스의 로그를 출력
- `-c`: 컨테이너 이름을 지정

```sh
# 실시간 로그 스트림 출력
$ k logs -f wrongpod
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory # 10초마다 로그가 생김
^C # ctrl + c로 탈출

# 이전 인스턴스의 로그 출력
k logs wrongpod  -p
Error from server (BadRequest): previous terminated container "wrongpod" in pod "wrongpod" not found
# 이전 인스턴스가 없으므로 아무것도 출력되지 않음
# Deployment처럼 재시작 되는 파드에서 사용

# 컨테이너 이름 지정
$ k logs wrongpod -c wrongpod
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
ls: /nonexistent: No such file or directory
...
# 컨테이너가 여럿 있는 파드에서 사용
```

파드의 컨테이너 로그를 직접 확인하려면 `crictl logs` 명령을 사용할 수 있습니다. 파드가 실행 중인 노드에서 `crictl ps`로 컨테이너 ID를 확인한 후, `crictl logs`로 로그를 확인할 수 있습니다:

```sh
$ crictl ps -a
$ crictl logs <container-id>
```

또 파드 컨테이너 로그를 실행 중인 노드의 파일시스템에서 직접 확인할 수도 있습니다. 상위 디렉토리 경로와 파일 이름 형식은 다음과 같습니다:
- /var/log/containers: `<pod-name>_<pod-namespace>_<container-name>-<container-id>.log`
- /var/log/pods: `<pod-namespace>_<pod-name>_<uid>/<cotainer-name>/<attempts>.log`

컨테이너 관리 도구(`crictl`) 또는 파일로 직접 로그를 확인하는 것은 쿠버네티스 코어 컴포넌트에 문제가 있어서 `kubectl`이 동작하지 않을 때 유용합니다.

### Describe
`kubectl describe` 명령어를 사용하여 파드에 대한 자세한 정보를 확인할 수 있습니다. 특히 State/Last State 섹션에서 파드의 현재 그리고 지난 인스턴스의 상태를 확인하고 이상이 있는지 판단할 수 있습니다.

위처럼 오류를 발생하지만 컨테이너 실행은 정상일 때 파드 상태 역시 정상입니다:

```sh
$ k describe pod wrongpod | grep -i state -A4
State:          Running
      Started:      Tue, 04 Apr 2023 04:09:24 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
```

하지만 잘못된 이미지 태그 설정으로 인해 컨테이너가 실행되지 않을 때는 다음과 같이 `State`와 `Last State`가 다르게 표시됩니다:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wrongpod2
  namespace: default
spec:
  containers:
    - name: wrongpod2
      image: busybox:wrongtag # 존재하지 않는 태그
      command:
        - "sh"
        - "-c"
        - "sleep infinity"
```

```sh
$ k describe po wrongpod2 | grep -i state -A4
    State:          Waiting
      Reason:       ErrImagePull
    Ready:          False
    Restart Count:  0
    Environment:    <none>

# 파드 목록 조회 시 STATUS에서도 상태의 이유 확인 가능
$ k get po wrongpod2
k get po wrongpod2
NAME        READY   STATUS             RESTARTS   AGE
wrongpod2   0/1     ImagePullBackOff   0          74s
```

`describe`는 파드 뿐만 아니라 다른 쿠버네티스 리소스에 대해서도 사용할 수 있습니다.

```sh
$ k -n kube-system describe deploy coredns
...(생략)
```

### Events
`describe` 출력 마지막에는 이벤트(Event) 목록이 출력됩니다. 이벤트는 객체와 관련한 클러스터 내에서 발생하는 중요한 변화나 상태 변경에 대한 알림입니다.

```sh
$ k describe po wrongpod2 | tail -n 8
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  2m16s                default-scheduler  Successfully assigned default/wrongpod2 to node-2
  Normal   Pulling    47s (x4 over 2m16s)  kubelet            Pulling image "busybox:wrongtag"
  Warning  Failed     46s (x4 over 2m15s)  kubelet            Failed to pull image "busybox:wrongtag": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/busybox:wrongtag": failed to resolve reference "docker.io/library/busybox:wrongtag": docker.io/library/busybox:wrongtag: not found
  Warning  Failed     46s (x4 over 2m15s)  kubelet            Error: ErrImagePull
  Warning  Failed     33s (x6 over 2m14s)  kubelet            Error: ImagePullBackOff
  Normal   BackOff    22s (x7 over 2m14s)  kubelet            Back-off pulling image "busybox:wrongtag"
```

예를 들어, 파드가 시작되거나 종료되는 경우, 노드가 다운되거나 복구되는 경우, 스토리지가 추가되거나 제거되는 경우 등이 있습니다. 이벤트는 클러스터의 운영 상태를 파악하고 문제를 해결하는 데 도움을 줍니다. 위에선 잘못된 이미지 태그를 검색하고 받는데 실패한 이벤트를 확인할 수 있습니다.

Event는 `kubectl get events` 명령으로도 확인할 수 있습니다. 이 명령은 `describe` 명령이 특정 객체와 관련한 이벤트를 출력하는 것과 달리 네임스페이스의 모든 이벤트를 출력합니다.

```sh
$ k get event
LAST SEEN   TYPE      REASON      OBJECT          MESSAGE
31m         Normal    Scheduled   pod/wrongpod    Successfully assigned default/wrongpod to node-2
30m         Normal    Pulling     pod/wrongpod    Pulling image "busybox"
31m         Normal    Pulled      pod/wrongpod    Successfully pulled image "busybox" in 1.395995264s (1.396022049s including waiting)
...(생략)
```

즉 Event는 네임스페이스 객체입니다.


---

## 참고

