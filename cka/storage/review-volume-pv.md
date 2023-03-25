# (Review) Volumes, Persistent Volumes

> 📘 Cluster: **k8s**(default)
<br> `vagrant provision` 또는
<br> `vagrant destroy -f && vagrant up`


<details>
<summary>
컨테이너 이미지 <code>nginx</code> 파드 (이름) <code>pod-vol</code>을 만들고 다음 볼륨에 연결하세요.
<br> - 타입: <code>hostPath</code>
<br> - 경로: /tmp/hostpath
</summary>
<pre><code>apiVersion: v1
kind: Pod
metadata:
  name: pod-vol
  namespace: default
spec:
  containers:
  - image: nginx</code></pre>
</details>