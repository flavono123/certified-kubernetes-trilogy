# ConfigMaps

ConfigMaps store data in key-value pairs which would be consumed in Pods.

Create a ConfigMap(`cm` is the abbreviation for `configmap`).

```shell
$ k create cm envs \
  --from-literal USER=flavono123 \
  --from-literal USERNAME=vonogoru123
configmap/envs created
$ k get cm envs -oyaml
apiVersion: v1
data:
  USER: flavono123
  USERNAME: vonogoru123
kind: ConfigMap
metadata:
  creationTimestamp: "2022-11-22T10:32:15Z"
  name: envs
  namespace: default
  resourceVersion: "128684"
  uid: 3c4163a4-9064-4e9e-9da9-3f31b9229352
root@node-1:~#

```

`--from-literal key=val` create data for a `key: val` pair. A ConfigMap object has a `.data` field, not a `.spec` field in other objects. The field has `key: val` pairs.

#### Configure as environment variables

A ConfigMap can be referenced in a Pod as environment variables of containers.

Create a Pod referencing the ConfigMap above.

```shell
# Generate the template for the manifest first
$ k run echo --image=busybox $do \
  --command /bin/echo -- '$(USER)' '$(USERNAME)' > pod-echo.yaml
# Edit `.spec.containers[0].env` field as below
$ vi pod-echo.yaml
$ cat pod-echo.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: echo
  name: echo
spec:
  containers:
  - command:
    - /bin/echo
    - $(USER)
    - $(USERNAME)
    image: busybox
    name: echo
    resources: {}
    env:
    - name: USER
      valueFrom:
        configMapKeyRef:
          name: envs
          key: USER
    - name: USERNAME
      valueFrom:
        configMapKeyRef:
          name: envs
          key: USERNAME
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

```

The field `.spec.containers[].env[].valueFrom.configMapKeyRef` of Pods can reference a ConfigMap and its data key, children fields `.name` and `.key` for each.

The Pod just say environment variables, `USER` and `USERNAME`, which are mapped to same data key of ConfigMap `envs`.

(`$ENV_VAR` is an interpolation syntax in kubernetes, btw)

Validate the result.

```shell
$ k apply -f pod-echo.yaml
pod/echo created
$ k logs -f echo
flavono123 vonogoru123
```

#### Configure as files in volume

Files in volume are another way to reference a ConfigMap.&#x20;

Create another ConfigMap `htmls` for a new Pod `nginx.`

```shell
$ echo "This is configured" > index.html
$ k create cm htmls --from-file index.html $do
apiVersion: v1
data:
  index.html: |
    This is configured
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: htmls

```

This time, we use another option, `--from-file,` which store to `.data` of `ConfigMap` the path and the contents of the file as a key and a value for each. This option is useful when values are too long.

Now, create `nginx` Pod,configure to it and test

```shell
$ k run nginx --image=nginx $do > pod-nginx.yaml
# Edit `.spec.containers[0].volumeMounts` and `.spec.volumes` fields as below
$ vi pod-nginx.yaml
$ cat pod-nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
    resources: {}
    volumeMounts:
    - name: htmls
      mountPath: /usr/share/nginx/html
      readOnly: true
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  volumes:
  - name: htmls
    configMap:
      name: htmls
      items:
      - key: index.html
        path: index.html
status: {}
$ k apply -f pod-nginx.yaml
pod/nginx created
# For brevity, we just request to the Pod in a node directly with its IP
$ k get po nginx -owide
NAME    READY   STATUS    RESTARTS   AGE   IP            NODE     NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          6s    172.16.2.12   node-3   <none>           <none>
$ curl 172.16.2.12
This is configured

```

You can see the file from the ConfigMap is configured well.

We'll cover the Volumes as soon. For now, we just configure the ConfigMap's `index.html` item to the path `/usr/share/nginx/html/index.html` of the container's file system of the Pod.

Cleanup the labs.

```shell
$ k delete cm envs htmls
configmap "envs" deleted
configmap "htmls" deleted
$ k delete po echo nginx
pod "echo" deleted
pod "nginx" deleted
$ k get cm,po
NAME                         DATA   AGE
configmap/kube-root-ca.crt   1      46h
$ rm pod-echo.yaml pod-nginx.yaml index.html
```

### Recap

* ConfigMaps store data in key-value pairs which can be configured to the Pod's containers.
* The data of ConfigMaps can be configured in two ways.
  * As environment variables, data of ConfigMap are placed in `.spec.containers[].env[].valueFrom.configMapKeyRef` .
  * As files in a volume, data of ConfigMap are placed in `.spec.volumes[].configMap` (then mount it from `.spec.containers[].volumeMounts)`.

### Labs

* What is written in the ConfigMap `kube-root-ca.crt` ? And what for? This would be covered in the CKA  course.

### References

* [https://kubernetes.io/docs/concepts/configuration/configmap/](https://kubernetes.io/docs/concepts/configuration/configmap/)
* [https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
