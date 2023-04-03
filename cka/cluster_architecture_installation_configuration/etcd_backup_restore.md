# Ectd Backup and Restore

Etcd는 Kubernetes의 상태와 구성 데이터를 저장하는 중앙 데이터 저장소입니다. 따라서 백업과 복원이 중요합니다. `etcdctl` 도구를 사용하여 Etcd 데이터베이스를 백업, 복원할 수 있습니다.

### 테스트 백업/복원 준비
Etcd 백업과 복원이 잘 됐는지 검증하기 위해 `default` 네임스페이스에 디플로이먼트 하나를 만듭니다.

```sh
$ k create deploy nginx --image=nginx --replicas 2
deployment.apps/nginx created
```

## `etcdctl`

`etcdctl`이 없다면 패키지를 다운로드 받습니다.

```sh
$ apt-get update && apt-get install -y etcd-client
```

`etcdctl`는 API v3를 사용해야합니다. 따라서 `ETCDCTL_API` 환경 변수를 `3`으로 설정합니다.

```sh
$ export ETCDCTL_API=3
```

패키지 설치와 환경변수 설정이 실습환경에는 이미 되어 있습니다. help 메세지에서도 현재 클라이언트가 사용 중인 버전을 확인할 수 있습니다.

```sh
$ etcdctl -h
NAME:
        etcdctl - A simple command line client for etcd3.

USAGE:
        etcdctl [flags]

VERSION:
        3.5.1

API VERSION:
        3.5
...(생략)
```

`etcdctl`을 사용할 때 기본적으로 필요한 옵션은 다음과 같습니다.
- `--endpoints`: Etcd 서버 주소
- `--cacert`: CA 인증서 파일 경로
- `--cert`: 클라이언트 인증서 파일 경로
- `--key`: 클라이언트 인증서 키 파일 경로

각 옵션의 값은 Etcd 파드의 컨테이너 실행 명령 옵션에서 확인할 수 있습니다.
```sh
$ k -n kube-system get po etcd-node-1 -o yaml | yq .spec.containers[0].command
- etcd
- --advertise-client-urls=https://10.178.0.8:2379
- --cert-file=/etc/kubernetes/pki/etcd/server.crt # --cert
- --client-cert-auth=true
- --data-dir=/var/lib/etcd
- --experimental-initial-corrupt-check=true
- --experimental-watch-progress-notify-interval=5s
- --initial-advertise-peer-urls=https://10.178.0.8:2380
- --initial-cluster=node-1=https://10.178.0.8:2380
- --key-file=/etc/kubernetes/pki/etcd/server.key # --key
- --listen-client-urls=https://127.0.0.1:2379,https://10.178.0.8:2379 # --endpoints
- --listen-metrics-urls=http://127.0.0.1:2381
- --listen-peer-urls=https://10.178.0.8:2380
- --name=node-1
- --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
- --peer-client-cert-auth=true
- --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
- --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
- --snapshot-count=10000
- --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt # --cacert
```

인증서 키 파일의 경우 쿠버네티스 PKI 디렉토리(/etc/kubernetes/pki/etcd/) 밑에서 바로 찾을 수도 있습니다.

모든 명령에 네가지 옵션이 항상 필요합니다. 백업을 하기 전에 옵션 값이 적절한지 healthcheck를 해보겠습니다.

```sh
$ etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 17.944533ms

# 현재 stat 확인
$ etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status
https://127.0.0.1:2379, a261df9ac83f9ae3, 3.5.6, 8.6 MB, true, false, 6, 489459, 489459,
```

## Etcd 백업
`etcdctl`의 `snapshot save` 명령을 사용해 현재 Etcd 데이터베이스를 백업할 수 있습니다. 인자로 백업 파일 경로를 넘겨줍니다.

```sh
$ etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /tmp/etcd-backup.db
...(생략)
Snapshot saved at /tmp/etcd-backup.db

# 백업 파일 stat 확인
$ etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot status /tmp/etcd-backup.db --write-out=table
Deprecated: Use `etcdutl snapshot status` instead.

+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 421a4733 |   451759 |       3396 |     8.6 MB |
+----------+----------+------------+------------+
```

## Etcd 복구
Etcd를 복구해야하는 상황을 가정하기 위해 백업 전에 만든 디플로이먼트를 삭제해보겠습니다.

```sh
$ k delete deploy nginx
deployment.apps "nginx" deleted
$ k get deploy,po
No resources found in default namespace.
```

상황을 만들기 위해 직접 지웠지만, 디플로이먼트가 실수 또는 사고로 지워졌고 매니페스트 또한 알 수 없다고 가정해보겠습니다. 이 때 백업한 Etcd 덤프 파일을 복구하여 디플로이먼트를 복구할 수 있습니다.

Etcd 덤프 파일을 복구하기 위해서는 `snapshot restore` 명령을 사용합니다. 인자로 덤프 파일 경로와 복구할 데이터베이스 경로를 넘겨줍니다.

```sh
$ etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-from-backup # 참고로 원래 데이터베이스는 /var/lib/etcd
...(생략)
```

Etcd 파드의 매니페스트를 수정하여 복구한 데이터베이스를 사용하도록 설정합니다.

```sh
$ vi /etc/kubernetes/manifests/etcd.yaml
...
spec:
  containers:
  - command:
    - etcd
...
    - --data-dir=/var/lib/etcd
...
    volumeMounts:
    - mountPath: /var/lib/etcd
      name: etcd-data
    - mountPath: /etc/kubernetes/pki/etcd
      name: etcd-certs
...
  volumes:
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
  - hostPath:
      path: /var/lib/etcd-from-backup # 여기를 수정
      type: DirectoryOrCreate
    name: etcd-data
```

파드 스펙의 볼륨과 볼륨마운트 그리고 옵션 플래그 `--data-dir`를 확인해보면, `etcd-data` 볼륨 경로를 수정하면 가장 적게 고치고 복구할 수 있는걸 알 수 있습니다.

매니페스트를 수정 후 저장 하면 Etcd 파드가 재시작 되는데 시간이 좀 걸릴 수 있습니다. 이 때 `kubectl` 명령이 동작하지 않는다면 `crictl ps`로 Etcd 파드가 재시작 되었는지 확인해보세요.

```sh
$ watch crictl ps
```

`crictl` `docker`와 비슷하게 컨테이너의 상태를 확인할 수 있는 명령입니다.

또 `etcd`가 재시작되면 `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`도 재시작 됩니다. 다른 컴포넌트도 재시작이 잘 되었는지 확인해보세요. 모든 컴포넌트 재시작이 잘 됐으면 백업 복구가 되었는지 확인합니다.

```sh
$ k get deploy,po
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   2/2     2            2           3h43m

NAME                         READY   STATUS    RESTARTS        AGE
pod/nginx-748c667d99-qgb4t   1/1     Running   1 (36m ago)     3h43m
pod/nginx-748c667d99-x8j2z   1/1     Running   1 (3h33m ago)   3h43m
```

---

### 참고
- [Operating etcd clusters for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
