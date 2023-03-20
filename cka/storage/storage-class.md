# StorageClass

> 📘 Cluster: **sk8s**
<br> `CLUSTER=sk8s vagrant provision` 또는
<br> `vagrant destroy -f && CLUSTER=sk8s vagrant up`

StorageClass는 PersistentVolume(PV)을 동적으로 생성하기 위한 오브젝트입니다. StorageClass를 사용하면 사용자는 스토리지 클래스의 특성을 정의할 수 있으며, PersistentVolumeClaim(PVC)에서 참조할 수 있습니다.

StorageClass는 특정 플랫폼 또는 특정 스토리지 솔루션에 따라서, 다음과 같은 다양한 프로비저닝을 지원합니다:
 - NFS
 - iSCSI
 - AWS EBS
 - GCE PD
 - Azure Disk
 
 이런 스토리지 클래스의 파라미터를 수정함으로써, 동적 프로비저닝 생성할 수 있습니다.

컨트롤플레인에 접속해 스토리지 클래스 목록을 확인합니다:
```sh
# k get storageclasses.storage.k8s.io
$ k get sc
NAME                   PROVISIONER                                                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path                                           Delete          WaitForFirstConsumer   false                  64s
nfs-client             cluster.local/nfs-provisioner-nfs-subdir-external-provisioner   Delete          Immediate              true                   59s
```

`local-path`와 `nfs-client` 두 개의 스토리지 클래스가 있습니다. 기본값인 `local-path` 먼저 살펴봅니다:
```yaml
# k get sc local-path -oyaml | yq
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  creationTimestamp: "2023-03-20T16:31:41Z"
  name: local-path
  resourceVersion: "34560"
  uid: 1ef91b36-2915-4bb1-af80-4cc897cb870a
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```
- 어노테이션 `"storageclass.kubernetes.io/is-default-class": "true"` 으로 기본 스토리지 클래스로 구성되어 있습니다.
- 프로비저너는 `rancher.io/local-path` 입니다.
- `reclaimPolicy`는 기본값 `Delete` 입니다.
  - `Delete`: 스토리지 클래스로 생성된 PV가 PVC에서 해제된 후(released), PV와 물리 스토리지를 모두 삭제합니다.
  - `Retain`: PV가 해제된 후에도 PV를 삭제하지 않고 남겨둔다.

`local-path`는, 이름과 프로비저너에서 알 수 있듯, 파드가 스케쥴되어 실행 중인 노드, 즉 로컬의 파일시스템을 볼륨으로 프로비저닝합니다. 따라서 생성되는 PV는 `hostPath` 타입입니다. 다음과 같은 PVC를 만듭니다:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-default-sc
  namespace: default
spec:
  # storageClassName: local-path
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
```

PVC의 스토리지 클래스 필드를 생략하면 기본 스토리지 클래스를 사용합니다:
```sh
$ k get pvc
NAME             STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-default-sc   Pending                                      local-path     4s
```

다음 파드를 생성해 방금 PVC를 볼륨으로 사용합니다:
```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod-pvc
  name: pod-pvc
  namespace: default
spec:
  containers:
  - image: nginx
    name: pod-pvc
    resources: {}
    volumeMounts:
    - name: pvc
      mountPath: /usr/share/nginx/html
  volumes:
  - name: pvc
    persistentVolumeClaim:
      claimName: pvc-default-sc
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

자주했던 것처럼 nginx의 인덱스 파일을 바꿔 검증하고 놀아봅시다. 파드가 생성되면 PV와 PVC를 확인해봅니다:
```sh
k get pv,pvc
NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS   REASON   AGE
persistentvolume/pvc-db7111b2-bef7-458d-92f6-0498f3b8e63c   100Mi      RWO            Delete           Bound    default/pvc-default-sc   local-path              2m23s

NAME                                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/pvc-default-sc   Bound    pvc-db7111b2-bef7-458d-92f6-0498f3b8e63c   100Mi      RWO            local-path     2m45s
```

PV가 자동, 동적으로 생성됐습니다. PV를 더 자세히 봅시다:
```yaml
$ k get pv pvc-db7111b2-bef7-458d-92f6-0498f3b8e63c -oyaml | yq .spec.hostPath
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: rancher.io/local-path
...
  name: pvc-db7111b2-bef7-458d-92f6-0498f3b8e63c
...
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 100Mi
...
  hostPath:
    path: /opt/local-path-provisioner/pvc-db7111b2-bef7-458d-92f6-0498f3b8e63c_default_pvc-default-sc
    type: DirectoryOrCreate
...
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-path
  volumeMode: Filesystem
status:
  phase: Bounde
```

어노테이션, 접근 모드, 반환 정책 그리고 용량 등에서 PVC와 스토리지 클래스 구성에 맞게 동적으로 생성된 것을 확인할 수 있습니다.

그리고 `hostPath` 타입이며 경로는 `/opt/local-path-provisioner/<pv>_<ns>_<pvc>` 임을 알 수 있습니다. 

파드가 실행 중인 노드를 확인하여 해당 노드에 들어가서 경로를 확인해봅시다:
```sh
k get po pod-pvc -owide
NAME      READY   STATUS    RESTARTS   AGE   IP            NODE     NOMINATED NODE   READINESS GATES
pod-pvc   1/1     Running   0          12m   172.16.1.16   node-3   <none>           <none>
```

저의 경우 `node-3` 입니다. 노드에 접속해 PV `hostPath`의 경로를 보면 빈 디렉토리가 있습니다:
```sh
# node-3
ll /opt/local-path-provisioner/pvc-db7111b2-bef7-458d-92f6-0498f3b8e63c_default_pvc-default-sc
total 8
drwxrwxrwx 2 root root 4096 Mar 20 17:12 ./
drwxr-xr-x 3 root root 4096 Mar 20 17:12 ../
```

따라서 파드로 HTTP 요청하면 실패할 것입니다. 간단하게 노드에서 파드 IP로 요청해봅니다:
```sh
$ curl 172.16.1.16
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx/1.23.3</center>
</body>
</html>
```

파드 PV 경로에 `index.html` 파일을 생성하고 다시 요청하면, 파일이 마운트되어 응답으로 돌아옵니다:
```sh
# node-3
$ echo "Certified Kubernetes Trilogy - CKA Storage Class" > /opt/local-path-provisioner/pvc-db7111b2-bef7-458d-92f6-0498f3b8e63c_default_pvc-default-sc/index.html
$ curl 172.16.1.16
Certified Kubernetes Trilogy - CKA Storage Class
```

이제 파드와 PVC를 지워보겠습니다:
```sh
$ k delete po pod-pvc
pod "pod-pvc" deleted
$ k delete pvc pvc-default-sc
persistentvolumeclaim "pvc-default-sc" deleted
...
$ k get po,pvc,pv
No resources found
```

시간이 조금 지난 후 확인하면 PV가 삭제된 걸 확인할 수 있습니다. 반환 정책(`reclaimPolicy`)이 `Delete`이기 때문입니다:
```sh
# node-3
ll /opt/local-path-provisioner/pvc-db7111b2-bef7-458d-92f6-0498f3b8e63c_default_pvc-default-sc/
ls: cannot access '/opt/local-path-provisioner/pvc-db7111b2-bef7-458d-92f6-0498f3b8e63c_default_pvc-default-sc/': No such file or directory
```

## 추가 문제
- `nfs-client`를 기본 스토리지 클래스로 바꿔봅시다.
- `nfs-client`를 사용한 PVC를 만들고 파드를 생성해 PV가 동적 프로비저닝 되도록 해봅시다.
  - NFS 파일시스템은 컨트롤플레인의 `/nfs-storage` 밑입니다.
- `nfs-client` 반환 정책(`.spec.reclaimPolicy`)을 `Retain`으로 바꾼 후 PV 프로비저닝 해봅시다.
