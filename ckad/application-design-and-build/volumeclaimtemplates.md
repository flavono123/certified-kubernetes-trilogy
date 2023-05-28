# VolumeClaimTemplates

스테이트풀셋의 요구사항 중 하나인 지속적인 스토리지를 갖기 위해 `.spec.volumeClaimTemplates`을 정의합니다. 이렇게하면 각 파드의 PVC를 동적 생성할 수 있습니다.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
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
      <br> - name: mysql
        image: mysql:5.7
        ports:
        <br> - containerPort: 3306
          name: mysql
        env:
        <br> - name: MYSQL_ALLOW_EMPTY_PASSWORD
          value: "1"
        volumeMounts:
        <br> - name: data-mysql
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  <br> - metadata:
      name: data-mysql
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 500Mi
      storageClassName: local-path
```

`.spec.volumeClaimTemplates`에 PVC에서 사용하는 스펙을 정의합니다. `storageClassName`을 지정하지 않으면 PV를 만들 때, 기본 스토리지 클래스가 사용됩니다.

```sh
k get pvc,pv
NAME                                       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/data-mysql-mysql-0   Bound    pvc-f82ee0ef-ae8b-4d06-98b7-a9b0f88bca0e   500Mi      RWO            local-path     55s
persistentvolumeclaim/data-mysql-mysql-1   Bound    pvc-69de449c-0e60-4f46-80a0-00297680267d   500Mi      RWO            local-path     49s
persistentvolumeclaim/data-mysql-mysql-2   Bound    pvc-3294c026-8ff6-4e81-90c8-4b29c81684fe   500Mi      RWO            local-path     43s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS   REASON   AGE
persistentvolume/pvc-3294c026-8ff6-4e81-90c8-4b29c81684fe   500Mi      RWO            Delete           Bound    default/data-mysql-mysql-2   local-path              80s
persistentvolume/pvc-69de449c-0e60-4f46-80a0-00297680267d   500Mi      RWO            Delete           Bound    default/data-mysql-mysql-1   local-path              87s
persistentvolume/pvc-f82ee0ef-ae8b-4d06-98b7-a9b0f88bca0e   500Mi      RWO            Delete           Bound    default/data-mysql-mysql-0   local-path
```

파드 생성마다, PVC가 생성되고, PV가 바인딩됩니다. 각 PVC 이름은 볼륨 클레임 템플릿의 이름 뒤에 파드 이름이 붙고, PV 이름은 pvc 뒤에 PVC uid가 붙습니다.

스테이트풀셋 스토리지의 지속성을 위해 파드가 삭제되더라도 PV는 삭제되지 않습니다. 만약 레플리카를 2로 줄여 `mysql-2` 파드가 삭제되더라도 PVC를 삭제하지 않고 나중에 `mysql-2` 파드가 다시 생성되면 기존 PV를 다시 사용할 수 있습니다.

```sh
$ k scale sts mysql --replicas 2
statefulset.apps/mysql scaled

$ k get pvc data-mysql-mysql-2
NAME                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
data-mysql-mysql-2   Bound    pvc-3294c026-8ff6-4e81-90c8-4b29c81684fe   500Mi      RWO            local-path     5m47s

$ k get pv pvc-3294c026-8ff6-4e81-90c8-4b29c81684fe
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS   REASON   AGE
pvc-3294c026-8ff6-4e81-90c8-4b29c81684fe   500Mi      RWO            Delete           Bound    default/data-mysql-mysql-2   local-path              5m57s
```

<details>
<summary>

Q1. 다음 스테이트풀셋을 생성하세요.
<br> - 이름: `web`
<br> - 레플리카: `3`
<br> - 레이블 셀렉터: `app=nginx`
<br> - 컨테이너: `nginx:1.14.2`
<br> - 볼륨 클레임 템플릿: `data-nginx`
<br> - Access Mode: `ReadWriteOnce`
<br> - 용량: `300Mi`
<br> - 마운트 경로: `/usr/share/nginx/html`
<br> - 스토리지 클래스: `local-path`
</summary>

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
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
        volumeMounts:
        - name: data-nginx
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  <br> - metadata:
      name: data-nginx
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 300Mi
      storageClassName: local-path
```

</details>

