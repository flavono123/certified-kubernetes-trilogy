# (Review) Volumes, Persistent Volumes

> 📘 Cluster: **k8s**(default)
<br> `vagrant provision` 또는
<br> `vagrant destroy -f && vagrant up`


<details>
<summary>
컨테이너 이미지 `nginx` 파드 (이름) `pod-vol`을 만들고 다음 볼륨에 연결하세요.
- 타입: `hostPath`
- 경로: /tmp/hostpath
</summary>
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-vol
  namespace: default
spec:
  containers:
  - image: nginx
```
</details>