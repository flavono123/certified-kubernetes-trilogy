<details>
<summary>

Q1. 다음 파드를 생성하세요.
<br> - 이름: `pod-with-req`
<br> - 컨테이너 이름: `app`
<br> - 컨테이너 이미지: `nginx:1.19.10`
<br> - 컨테이너 리소스 요청: cpu `200m`, memory `256Mi`
</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-req
spec:
  containers:
  - name: app
    image: nginx:1.19.10
    resources:
      requests:
        cpu: 200m
        memory: 256Mi
```

</details>

<details>

<summary>

Q2. 다음 파드를 생성하세요.
<br> - 이름: `pod-with-limit`
<br> - 컨테이너 이름: `app`
<br> - 컨테이너 이미지: `nginx:1.19.10`
<br> - 컨테이너 리소스 요청: cpu `200m`, memory `256Mi`
<br> - 컨테이너 리소스 제한: memory `256Mi`

</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-limit
spec:
  containers:
  - name: app
    image: nginx:1.19.10
    resources:
      requests:
        cpu: 200m
        memory: 256Mi
      limits:
        memory: 256Mi
```
