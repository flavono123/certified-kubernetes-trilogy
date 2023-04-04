# Application Troubleshooting

### 상태, 로그 확인
파드 실행에 문제 없는지 확인하려면, 앞서 배운 명령어를 사용해 상태와 로그를 확인합니다.
```sh
# 파드 상태 확인
$ k get po
$ k describe po <pod-name>
$ k get events --sort-by=.metadata.creationTimestamp --field-selector involvedObject.name=<pod-name>

# 파드 로그 확인
$ k logs <pod-name>
```

### 서비스 연결 문제
애플리케이션이 실행 중인 파드 상태는 정상이지만 서비스 연결이 되지 않는 경우가 있습니다. 먼저 의심해볼 수 있는 것은 서비스의 레이블 셀렉터가 파드의 레이블과 일치하는지 확인해야 합니다. 다음처럼 레이블 셀렉터가 일치하지 않으면 서비스는 파드를 찾을 수 없습니다.

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx-pod
spec:
  containers:
    - name: nginx
      image: nginx
      ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    wrong: selector
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

```sh
$ k get svc,po
NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   4d16h
service/nginx        ClusterIP   10.105.248.35   <none>        80/TCP    35s

NAME            READY   STATUS    RESTARTS   AGE
pod/nginx-pod   1/1     Running   0          35s

$ k run test --rm -it --image=busybox --restart=Never -- wget -O- nginx
If you don't see a command prompt, try pressing enter.
wget: can't connect to remote host (10.105.248.35): Connection refused
pod "test" deleted
pod default/test terminated (Error)
```

위처럼 파드의 상태는 실행 중이고 로그에도 이상이 없지만, 연결된 서비스로 요청 시 응답을 하지 않으면 의심해볼 수 있습니다. 서비스의 레이블 셀렉터를 수정해서 파드를 찾을 수 있도록 해야 합니다.

```yaml
# k edit svc nginx
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx-pod # 레이블 셀렉터 수정
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

```sh
$ k run test --rm -it --image=busybox --restart=Never -- wget -qO- nginx
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
pod "test" deleted
```

또 다른 경우는 서비스의 포트가 파드의 포트와 일치하지 않는 경우입니다. 서비스의 `spec.ports.targetPort`가 파드의 `spec.containers.ports.containerPort`가 일치해야 합니다. 서비스 스펙이 헷갈리지 않도록 주의해야 합니다.
- `port`: 서비스의 포트
- `targetPort`: 파드의 포트

### 디버깅 파드
위에서 서비스 응답을 확인하기 위해 `busybox` 이미지의 파드를 생성했습니다. 서비스 같은 네트워크 문제를 해결할 때 `busybox`로 임시 파드를 만들어 디버깅 할 수 있습니다. 또 명령을 여러번 실행할 땐 쉘을 실행해서 명령을 반복해서 실행할 수 있습니다.

```sh
$ k run test --rm -it --image=busybox --restart=Never -- sh
If you don't see a command prompt, try pressing enter.
/ #
/ #
/ # wget -qO- nginx
...(생략)
```
- `--rm`: 파드가 종료되면 자동으로 삭제
- `-it`: 파드의 표준 입력을 활성화하고 터미널을 할당
- `--restart=Never`: 파드가 종료되면 자동으로 재시작하지 않음

단순 서비스 응답 뿐만 아니라 포트가 열려 있는지, DNS 쿼리가 정상적으로 되는지 등 다양한 네트워킹 디버깅에도 사용할 수 있습니다.

<details>
<summary>Q1. 다음 매니페스트를 적용하고 <code>ckt-ts-app-svc1</code>의 응답이 성공(200)하도록 수정해보세요.</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ckt-ts-app-svc1
  namespace: default
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80 # 파드의 containrPort와 일치하도록 수정
```

확인

```sh
$ k run test --rm -it --image=busybox --restart=Never -- sh
/ # wget -qO- ckt-ts-app-svc1 --server-response > /dev/null
  HTTP/1.1 200 OK # 응답코드 확인
  ...
```

</details>

```sh
$ k apply -f https://raw.githubusercontent.com/flavono123/certified-kubernetes-trilogy/feature/cka/tbshooot/resources/manifests/application_troubleshooting/1.yaml
```
