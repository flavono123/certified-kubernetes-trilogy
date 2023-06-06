<details>
<summary>

Q1. 다음 파드를 생성하세요.
- 이름: `multi-con-pod`
- 컨테이너1 이름: `con1`
- 컨테이너1 이미지: `nginx:1.19.10`
- 컨테이너2 이름: `con2`
- 컨테이너2 이미지: `busybox:1.32.1`
- 컨테이너2 명령어: `sleep 3600`
</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-con-pod
spec:
  containers:
  - name: con1
    image: nginx:1.19.10
  - name: con2
    image: busybox:1.32.1
    command:
    - sleep
    - "3600"
```
</details>

<details>
<summary>

Q2. 다음 파드를 생성하세요.
- 이름: `multi-con-pod2`
- 컨테이너1 이름: `con1`
- 컨테이너1 이미지: `nginx:1.19.10`
- 컨테이너1 리소스 요청: cpu `200m`, memory `256Mi`
- 컨테이너2 이름: `con2`
- 컨테이너2 이미지: `busybox:1.32.1`
- 컨테이너2 명령어: `sleep 3600`
- 컨테이너2 리소스 요청: cpu `100m`, memory `128Mi`

</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-con-pod2
spec:
  containers:
  - name: con1
    image: nginx:1.19.10
    resources:
      requests:
        cpu: 200m
        memory: 256Mi
  - name: con2
    image: busybox:1.32.1
    command:
    - sleep
    - "3600"
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
```
</details>

<details>
<summary>

Q3. 파드 `multi-con-pod`의 컨테이너 로그를 각각 확인하세요.
</summary>

```sh
$ k logs multi-con-pod -c con1

$ k logs multi-con-pod -c con2
```

</details>

<details>

<summary>

Q4. 컨테이너 `con1`의 로그 파일, `/var/log/nginx/access.log`를 컨테이너 `con2`의 표준출력으로 출력하세요.
- 이름: `multi-con-pod3`
- 컨테이너1 이름: `con1`
- 컨테이너1 이미지: `nginx:1.19.10`
- 컨테이너2 이름: `con2`
- 컨테이너2 이미지: `busybox:1.32.1`
- 컨테이너2 명령어: `tail -f /var/log/nginx/access.log`
- 볼륨 이름: `nginx-log`
- 볼륨 타입: `emptyDir`
- 볼륨 마운트 경로: `/var/log/nginx`

</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-con-pod3
spec:
  containers:
  - name: con1
    image: nginx:1.19.10
    volumeMounts:
    - name: nginx-log
      mountPath: /var/log/nginx
  - name: con2
    image: busybox:1.32.1
    command:
    - tail
    - -f
    - /var/log/nginx/access.log
    volumeMounts:
    - name: nginx-log
      mountPath: /var/log/nginx
  volumes:
  - name: nginx-log
    emptyDir: {}
```

```sh
# 파드로 요청
$ curl 172.16.25.1

# 컨테이너 로그 확인
$ k logs multi-con-pod3 -c con2
172.16.25.1 - - [03/Jun/2023:04:26:23 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.68.0" "-"
```

</details>

<details>

<summary>

Q5. 파드 `multi-con-pod4`의 컨테이너 `con2`에서 `http://localhost` 요청 결과를 확인하세요.
- 이름: `multi-con-pod4`
- 컨테이너1 이름: `con1`
- 컨테이너1 이미지: `nginx:1.19.10`
- 컨테이너2 이름: `con2`
- 컨테이너2 이미지: `busybox:1.32.1`
- 컨테이너2 명령어: `sh -c "wget -qO - http://localhost && sleep 3600"`

</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-con-pod4
spec:
  containers:
  - name: con1
    image: nginx:1.19.10
  - name: con2
    image: busybox:1.32.1
    command:
    - sh
    - -c
    - "wget -qO - http://localhost && sleep 3600"
```

```sh
$ k logs multi-con-pod4 -c con2

# 직접 확인
$ k exec multi-con-pod4 -c con2 -it -- wget -qO - http://localhost
```

</details>
