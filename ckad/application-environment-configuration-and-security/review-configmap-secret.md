<details>
<summary>

Q1. 다음 컨피그맵을 생성하세요.
<br> - 이름: `app-cfg`
<br> - `database_url: mongodb://dummy-db-host:27017/my-database`
<br> - `api_key: 4a8f9b0c5d3e2f1a6b7c8d9e0f3a2b1`
<br> - `logging_level: debug`

</summary>

```sh
# from-literal 옵션 사용
$ k create cm app-cfg --from-literal=database_url=mongodb://dummy-db-host:27017/my-database --from-literal=api_key=4a8f9b0c5d3e2f1a6b7c8d9e0f3a2b1 --from-literal=logging_level=debug

# from-file 옵션 사용
$ mkdir -p data
$ echo -n "mongodb://dummy-db-host:27017/my-database" > data/database_url
$ echo -n "4a8f9b0c5d3e2f1a6b7c8d9e0f3a2b1" > data/api_key
$ echo -n "debug" > data/logging_level
$ k create cm app-cfg --from-file=data

# from-env-file 옵션 사용
$ cat <<EOF > data.env
database_url=mongodb://dummy-db-host:27017/my-database
api_key=4a8f9b0c5d3e2f1a6b7c8d9e0f3a2b1
logging_level=debug
EOF

$ k create cm app-cfg --from-env-file=data.env
```

</details>

<details>
<summary>

Q2. 다음 시크릿을 생성하세요.
<br> - 이름: `app-cred`
<br> - `username: admin`
<br> - `password: 1234`

</summary>

```sh
# from-literal 옵션 사용
$ k create secret generic app-cred --from-literal=username=admin --from-literal=password=1234

# from-file 옵션 사용
$ mkdir -p secrets
$ echo -n "admin" > secrets/username
$ echo -n "1234" > secrets/password
$ k create secret generic app-cred --from-file=secrets

# from-env-file 옵션 사용
$ cat <<EOF > secrets.env
username=admin
password=1234
EOF

$ k create secret generic app-cred --from-env-file=secrets.env
```

<details>
<summary>

Q3. 파드에서 컨테이너 환경변수로 `app-cfg` 컨피그맵의 값들을 사용하세요.
<br> - 파드 이름: `pod-with-cfg`
<br> - 컨테이너 이름: `app`
<br> - 컨테이너 이미지: `nginx:1.19.10`

</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-cfg
spec:
  containers:
  - name: app
    image: nginx:1.19.10
    envFrom:
    - configMapRef:
        name: app-cfg
```

```sh
# 확인
$ k exec pod-with-cfg -- env | grep -E '(database_url|api_key|logging_level)'
```

</details>

<details>
<summary>

Q4. 파드에서 컨테이너 환경변수로 `app-cred` 시크릿 중 `username`의 값만 사용하세요.
<br> - 파드 이름: `pod-with-cred`
<br> - 컨테이너 이름: `app`
<br> - 컨테이너 이미지: `nginx:1.19.10`
<br> - 컨테이너 환경변수: `USERNAME`

</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-cred
spec:
  containers:
  - name: app
    image: nginx:1.19.10
    env:
    - name: USERNAME
      valueFrom:
        secretKeyRef:
          name: app-cred
          key: username
```


```sh
# 확인
$ k exec pod-with-cred -- env | grep USERNAME
```

</details>

<details>
<summary>

Q5. 파드에서 컨테이너 다음 경로에 `app-cfg` 컨피그맵의 값들을 마운트하세요.
<br> - 파드 이름: `pod-mnt-cfg`
<br> - 컨테이너 이름: `app`
<br> - 컨테이너 이미지: `nginx:1.19.10`
<br> - 컨테이너 마운트 경로: `/etc/config`

</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-mnt-cfg
spec:
  containers:
  - name: app
    image: nginx:1.19.10
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-cfg
```

```sh
# 확인
$ k exec pod-mnt-cfg -- ls /etc/config
$ k exec pod-mnt-cfg -- cat /etc/config/api_key
$ k exec pod-mnt-cfg -- cat /etc/config/database_url
$ k exec pod-mnt-cfg -- cat /etc/config/logging_level
```

</details>
