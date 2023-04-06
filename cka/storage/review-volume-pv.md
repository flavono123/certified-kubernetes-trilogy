# (Review) Volumes, Persistent Volumes
> 📘 Cluster: **k8s**(default)
<br> `vagrant provision` 또는
<br> `vagrant destroy -f && vagrant up`


<details>
<summary><b>1. Volume</b>
<br> 컨테이너 이미지 <code>nginx</code> 사용해  <code>pod-vol</code> 이름의 파드 만들고 다음 볼륨에 연결하세요.
<br> - 컨테이너 포트: 80
<br> - 타입: <code>hostPath</code>
<br> - 볼륨 이름: <code>html</code>
<br> - 볼륨 경로: /data/html
<br> - 마운트 경로: /usr/share/nginx/html
</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-vol
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: html
      mountPath: "/usr/share/nginx/html"
  volumes:
  - name: html
    hostPath:
      path: /data/html
```

```sh
$ k get pod pod-vol -owide
# 노드 확인 후 노드의 /data/html 경로에 index.html 파일 생성(e.g. node-2)
$ ssh node-2
$ su -i
$ echo "Hello from node-2" > /data/html/index.html
# 파드의 컨테이너에서 index.html 파일 확인
$ k exec -it pod-vol -- cat /usr/share/nginx/html/index.html
# 또는 curl 요청으로 index.html 파일 확인
$ curl < pod-id >
```
</details>

<details>
<summary><b>2. Persistent Volume</b>
<br> <code>pv-1</code> 이름의 Persistent Volume 만들고 다음과 같이 설정하세요.
<br> - 타입: <code>hostPath</code>
<br> - 경로: /data/pv-1
<br> - 용량: 100Mi
<br> - 액세스 모드: <code>ReadWriteOnce</code>
</summary>

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-1
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/pv-1
```

</details>

<details>
<summary><b>3. Persistent Volume Claim</b>
<br> <code>pvc-1</code> 이름의 Persistent Volume Claim 만들고 다음과 같이 설정하세요.
<br> - 요청 용량: 100Mi
<br> - 액세스 모드: <code>ReadWriteOnce</code>
</summary>

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
```

</details>

<details>
<summary><b>4. PVC 파드 연결</b>
<br> <code>pod-pvc</code> 이름의 파드 만들고 다음 볼륨에 연결하세요.
<br> - 컨테이너 이미지: <code>busybox</code>
<br> - 컨테이너 명령: <code>/bin/sh -c "while true; do echo $(date -u) >> /data/log.txt; sleep 5; done"</code>
<br> - 타입: <code>persistentVolumeClaim</code>
<br> - 마운트 경로: /data
</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-pvc
spec:
  containers:
  - name: busybox
    image: busybox
    command:
    - /bin/sh
    - -c
    - "while true; do echo $(date -u) >> /data/log.txt; sleep 5; done"
    volumeMounts:
    - name: pvc-volume
      mountPath: "/data"
  volumes:
  - name: pvc-volume
    persistentVolumeClaim:
      claimName: pvc-1
```

```sh
# 파드의 컨테이너에서 log.txt 파일 확인
$ k exec -it pod-pvc -- cat /data/log.txt
```

</details>

<details>
<summary><b>5. PV - PVC 바인딩</b>
<br> 다음 PV, <code>pv-2</code>, 와 PVC, <code>pvc-2</code> 를 바인딩 하도록 <b>PVC</b>를 수정하세요.
</summary>

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-2
spec:
  accessModes:
    - ReadWriteOnce # pv-2의 것과 동일하게 수정
  resources:
    requests:
      storage: 50Mi # pv-2의 용량보다 작거나 같게 수정
```

```sh
# pv-2, pvc-2 바인딩 확인
$ k get pv,pvc
```

</details>

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-2
spec:
  capacity:
    storage: 50Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/pv-2
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-2
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Mi
```
