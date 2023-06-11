<details>
<summary>

Create a new *PersistentVolume* named `ckad-pv`. It should have a capacity of *2Gi*, accessMode *ReadWriteOnce*, hostPath `/Volumes/Data` and no storageClassName defined.
<br><br>

Next create a new PersistentVolumeClaim in Namespace `default` named `ckad-pvc` . It should request *2Gi* storage, accessMode *ReadWriteOnce* and should not define a storageClassName. The *PVC* should bound to the *PV* correctly.
<br><br>

Finally create a new *Deployment* `ckad-deploy` in Namespace `default` which mounts that volume at `/tmp/ckad-data`. The *Pods* of that *Deployment* should be of image `httpd:2.4.41-alpine`.

</summary>

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
 name: ckad-pv
spec:
 capacity:
  storage: 2Gi
 accessModes:
  - ReadWriteOnce
 hostPath:
  path: /Volumes/Data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ckad-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
     storage: 2Gi
  storageClassName: ""
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: ckad-deploy
  name: ckad-deploy
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ckad-deploy
  template:
    metadata:
      labels:
        app: ckad-deploy
    spec:
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: ckad-pvc
      containers:
      - image: httpd:2.4.41-alpine
        name: container
        volumeMounts:
        - name: data
          mountPath: /tmp/ckad-data
```

</details>
