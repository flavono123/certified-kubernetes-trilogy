# Headless Services

헤드리스 서비스는 ClusterIP 타입의 서비스지만 `.spec.clusterIP`를 None으로 설정합니다. 따라서 클러스터 내부에서 통신할 수 있지만 서비스 IP를 할당 받진 않습니다. 스테이트풀셋을 헤드리스 서비스로 노출하면 각 파드에 **고유한(unique) 네트워크 식별자**를 부여할 수 있습니다.

먼저 헤드리스 서비스를 생성합니다:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-svc
spec:
  ports:
  - port: 3306
    name: mysql
  clusterIP: None
  selector:
    app: mysql
```

- `spec.clusterIP`를 None으로 설정합니다.
- `spec.selector`로 스테이트풀셋의 파드를 선택합니다.
- `metadata.name`는 거버닝 서비스(governing service) 이름입니다. 스테이트풀셋 각 파드에 요청 시 DNS 서브도메인이 됩니다.


그리고 스테이트풀셋을 생성합니다.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-svc
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ALLOW_EMPTY_PASSWORD
          value: "1"
        ports:
        - containerPort: 3306
          name: mysql
```

컨테이너 이미지는, 스테이트풀 애플리케이션의 예제로, mysql을 사용했습니다. 환경변수 `MYSQL_ALLOW_EMPTY_PASSWORD=1` 로 비밀번호를 입력하지 않아도 되도록 간단하게 구성하고 포트는 mysql의 3306을 사용합니다.

여기서 주목할 것은 `spec.serviceName`입니다. 헤드리스 서비스의 이름과 동일하게 설정합니다. 이렇게 하면 `파드.거버닝_서비스` 도메인으로 접근할 수 있습니다. 예를 들어 `mysql-0.mysql-svc`는 mysql-0 파드에 접근합니다.

```sh
$ k describe svc mysql-svc | grep -i endpoints
Endpoints:         172.16.45.37:3306,172.16.5.76:3306,172.16.5.77:3306

$ k get po -l app=mysql -owide
NAME      READY   STATUS    RESTARTS   AGE     IP             NODE     NOMINATED NODE   READINESS GATES
mysql-0   1/1     Running   0          3m36s   172.16.5.76    node-2   <none>           <none>
mysql-1   1/1     Running   0          3m34s   172.16.45.37   node-3   <none>           <none>
mysql-2   1/1     Running   0          3m33s   172.16.5.77    node-2   <none>           <none>
```

헤드리스 서비스는 엔드포인트로 각 파드의 IP를 가지고 있습니다. 도메인 이름이 DNS에 등록되어 있는지 확인해봅니다:

```sh
$ k run test-conn --image busybox -it --rm --restart Never -- nslookup -type=srv mysql-svc
Server:         10.96.0.10
Address:        10.96.0.10:53

...

mysql-svc.default.svc.cluster.local     service = 0 33 3306 mysql-0.mysql-svc.default.svc.cluster.local
mysql-svc.default.svc.cluster.local     service = 0 33 3306 mysql-1.mysql-svc.default.svc.cluster.local
mysql-svc.default.svc.cluster.local     service = 0 33 3306 mysql-2.mysql-svc.default.svc.cluster.local

...

pod "test-conn" deleted
pod default/test-conn terminated (Error)

$ k run test-conn --image busybox -it --rm --restart Never -- nc -zv -w 3 mysql-0.mysql-svc 3306
mysql-0.mysql-svc (172.16.5.76:3306) open
pod "test-conn" deleted
$ k run test-conn --image busybox -it --rm --restart Never -- nc -zv -w 3 mysql-1.mysql-svc 3306
mysql-1.mysql-svc (172.16.45.37:3306) open
pod "test-conn" deleted
$ k run test-conn --image busybox -it --rm --restart Never -- nc -zv -w 3 mysql-2.mysql-svc 3306
mysql-2.mysql-svc (172.16.5.77:3306) open
pod "test-conn" deleted
```

포트와 같이 지정했기 때문에 `nslookup` 시 타입 `srv`도 같이 넘겨줍니다. 그러면 `mysql-svc`의 DNS 서브도메인에 대한 정보를 확인할 수 있습니다. `nc` 명령으로 각 파드에 포트를 확인하면 정상적으로 접근할 수 있습니다.


<details>
<summary>Q1. 다음 헤드리스 서비스를 생성하세요.
<br> - 이름: <code>web</code>
<br> - 포트: <code>8080</code>
<br> - 레이블 셀렉터: <code>app=nginx</code>
</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  ports:
  - port: 8080
    name: http
  clusterIP: None
  selector:
    app: nginx
```
</details>

<details>
<summary>Q2. 위 헤드리스 서비스로 노출되는 스테이트풀셋을 생성하세요.
<br> - 이름: <code>web</code>
<br> - 레플리카: <code>3</code>
<br> - 레이블 셀렉터: <code>app=nginx</code>
<br> - 컨테이너 이미지: <code>nginx:1.14.2</code>
<br> - 컨테이너 포트: <code>80</code>
</summary>

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: web
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
        image: nginx:1.14.2
        ports:
        - containerPort: 80
          name: http
```
</details>

