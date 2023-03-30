# (Review) Services, DNS, Ingresses

> 📘 Cluster: **k8s**(default)
<br> `vagrant provision` 또는
<br> `vagrant destroy -f && vagrant up`

<details>
<summary><b>1. Services - ClusterIP</b>
<br>  파드를 만들고 같은 이름의 서비스로 노출하세요.
<br> - 서비스 포트: <code>80</code>
<br> - 서비스 타입: <code>ClusterIP</code>
<br> - 파드 이름: <code>pod-svc</code>
<br> - 컨테이너 이미지: <code>nginx</code>
<br> - 컨테이너 포트: <code>80</code>
</summary>

```sh
$ k run pod-svc --image=nginx --port=80
$ k expose pod pod-svc --port=80 --target-port=80 # --type=ClusterIP(default)
```

확인

```sh
$ k run test-svc --image=busybox --restart=Never --rm -it -- wget -O- pod-svc
```

</details>

<details>
<summary><b>2. Services - NodePort</b>
<br>  파드를 만들고 같은 이름의 <code>NodePort</code> 서비스로 노출하세요.
<br> - 서비스 포트: <code>80</code>
<br> - 노드 포트: <code>30080</code>
<br> - 서비스 타입: <code>NodePort</code>
<br> - 파드 이름: <code>pod-svc-nodeport</code>
<br> - 컨테이너 이미지: <code>nginx</code>
<br> - 컨테이너 포트: <code>80</code>
</summary>

```sh
$ k run pod-svc-nodeport --image=nginx --port=80
$ k expose pod pod-svc-nodeport --port=80 --target-port=80 --type=NodePort --node-port=30080
```

확인

```sh
$ curl localhost:30080
# 또는 노드의 다른 IP 사용
# curl 192.168.1.2:30080
# curl 192.168.1.3:30080
# curl 192.168.1.4:30080
```


</details>

<details>
<summary><b>3. DNS</b>
<br> 다음 매니페스트를 적용하고 <code>busybox</code> 이미지를 이용해 서비스와 파드 각각 DNS 이름으로 접근하는 명령을 써보세요.
</summary>

```sh
# 서비스 DNS 요청
$ k run test-svc-dns --image=busybox --restart=Never --rm -it -- wget -O- nginx-hostname
# 또는 k run test-svc-dns --image=busybox --restart=Never --rm -it -- wget -O- nginx-hostname.default.svc.cluster.local
# 또는 k run test-svc-dns --image=busybox --restart=Never --rm -it -- wget -O- nginx-hostname.default.svc
# 또는 k run test-svc-dns --image=busybox --restart=Never --rm -it -- wget -O- nginx-hostname.default

# 파드 DNS 요청
$ k get pod nginx-hostname -owide # IP 확인 후 .을 -로 변경
$ POD_DNS=10-101-146-21 # 예시
# 또는 POD_DNS=10-101-146-21.default.pod.cluster.local
# 또는 POD_DNS=10-101-146-21.default.pod
# 명령으로 만드는 방법
# POD_DNS=$(k get pod nginx-hostname -ojsonpath='{.status.podIP}' | sed 's/\./-/g')
# 또는 POD_DNS=$(k get pod nginx-hostname -oyaml | yq .status.podIP | sed 's/\./-/g')
$ k run test-pod-dns --image=busybox --restart=Never --rm -it -- wget -O- $POD_IP
```

</details>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-hostname
  namespace: default
spec:
  selector:
    app: nginx-hostname
  ports:
- protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-hostname
  namespace: default
  labels:
    app: nginx-hostname
spec:
  containers:
  - name: nginx-hostname
    image: vonogoru123/nginx-hostname
    ports:
    - containerPort: 80
```

<details>
<summary><b>4. Ingress</b>
<br> 위 서비스 <code>pod-svc</code>와 <code>nginx-hostname</code>을 백엔드로 하는 <code>Ingress</code>를 만들어보세요.
<br> 인그레스 이름: <code>ingress-test</code>
<br> - 백엔드1
<br>   - 서비스: <code>pod-svc</code>
<br>   - 경로: <code>/nginx</code>
<br> - 백엔드2
<br>   - 서비스: <code>nginx-hostname</code>
<br>   - 경로: <code>/podname</code>
</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-test
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /nginx
        pathType: Prefix
        backend:
          service:
            name: pod-svc
            port:
              number: 80
      - path: /podname
        pathType: Prefix
        backend:
          service:
            name: nginx-hostname
            port:
              number: 80
```

</details>