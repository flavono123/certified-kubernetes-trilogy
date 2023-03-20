# Labels and Selectors

### Labels

_Labels_ are key/value pairs that are attached to objects, such as pods.

Run a pod and check labels attached on that.

```shell
$ k run test --image=httpd
pod/test created
$ k get po test --show-labels
NAME   READY   STATUS    RESTARTS   AGE   LABELS
test   1/1     Running   0          9s    run=test
$ k get po test -oyaml | yq '.metadata.labels'
run: test
```

You can check labels with a **`--show-labels`**`(default=false)` option in subcommand `get`.

You also can see them in the **`.metadata.labels` field** in a YAML declaration of an object.

As you see, a pod(imperatively ran) has the default label, `run: <podname>`.

### Label to objects

You can label the pod by a subcommand **`label`**.

```shell
$ k label po test env=test
pod/test labeled
$ k get po test --show-labels
NAME   READY   STATUS    RESTARTS   AGE   LABELS
test   1/1     Running   0          30h   env=test,run=test
```

Run another pod. Then `edit` its manifest or `patch` to it, you also can label the pod.

```shell
$ k run dev --image=nginx
pod/dev created
$ k edit po dev
# Add a `env: dev` under the `.metadata.labels' and save a tempfile
# Or patch with ` k patch po dev --patch  '{ "metadata": { "labels": { "env": "dev" } } }`
# Or just `k label po dev env=dev`
$ k get po --show-labels
NAME   READY   STATUS    RESTARTS   AGE     LABELS
dev    1/1     Running   0          5m40s   env=dev,run=dev
test   1/1     Running   0          30h     env=test,run=test
```

### Selector

You can select pods by label selectors with a **`-l(--label)`** option.

```shell
$ k get po -l run=dev
NAME   READY   STATUS    RESTARTS   AGE
dev    1/1     Running   0          82m
$ k get po -l env=test
NAME   READY   STATUS    RESTARTS   AGE
test   1/1     Running   0          31h
$ k get po -l env!=test
NAME   READY   STATUS    RESTARTS   AGE
dev    1/1     Running   0          84m
```

The above selectors are _equality-based_ selectors which use `=(==)` for equality and `!=` for inequality.

Anther selector type is a _set-based_ selector.

```shell
# Run one more pod
$ k run prod --image=httpd
pod/prod created
$ k label po prod env=prod
pod/prod labeled
$ k label po prod prod=true
pod/prod labeled
$  k get po --show-labels
NAME   READY   STATUS    RESTARTS   AGE   LABELS
dev    1/1     Running   0          93m   env=dev,run=dev
prod   1/1     Running   0          23s   env=prod,run=prod
test   1/1     Running   0          31h   env=test,prod=true,run=test

$ k get po -l 'env in (dev, prod)' --show-labels
NAME   READY   STATUS    RESTARTS   AGE     LABELS
dev    1/1     Running   0          97m     env=dev,run=dev
prod   1/1     Running   0          3m43s   env=prod,prod=true,run=prod
$ k get po -l 'env notin (dev, prod)' --show-labels
NAME   READY   STATUS    RESTARTS   AGE   LABELS
test   1/1     Running   0          31h   env=test,run=test
$ k get po -l 'prod' --show-labels
NAME   READY   STATUS    RESTARTS   AGE     LABELS
prod   1/1     Running   0          2m10s   env=prod,prod=true,run=prod
$ k get po -l '!prod' --show-labels
NAME   READY   STATUS    RESTARTS   AGE   LABELS
dev    1/1     Running   0          95m   env=dev,run=dev
test   1/1     Running   0          31h   env=test,run=test
```

Operators in set-based selectors are following:

* `<key> in (val1[, val2, ...])`&#x20;
* `<key> notin (val1[, val2, ...])`&#x20;
* `<key>` and `!<key>`&#x20;

The comma(`,`) can be used as an AND operator.

```shell
$ k get po -l '!prod,env=dev' --show-labels
NAME   READY   STATUS    RESTARTS   AGE    LABELS
dev    1/1     Running   0          102m   env=dev,run=dev
```

### nodeSelector and nodeName

**A pod can be scheduled on nodes with labels**. First, check where the current pods in with an `-owide` option.

```
$ k get po -owide
NAME   READY   STATUS    RESTARTS   AGE    IP             NODE     NOMINATED NODE   READINESS GATES
dev    1/1     Running   0          104m   172.16.247.7   node-2   <none>           <none>
prod   1/1     Running   0          11m    172.16.247.8   node-2   <none>           <none>
test   1/1     Running   0          32h    172.16.247.6   node-2   <none>           <none>
```

In my case, all pod in the `node-2`.

To schedule a pod in `node-3`, use the **`nodeSelector`**`.`

```
$ k get no --show-labels
NAME     STATUS   ROLES           AGE   VERSION   LABELS
node-1   Ready    control-plane   41h   v1.25.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=node-1,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
node-2   Ready    <none>          41h   v1.25.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=node-2,kubernetes.io/os=linux
node-3   Ready    <none>          41h   v1.25.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=node-3,kubernetes.io/os=linux
```

Nodes also have labels and we use one of them, `kubernetes.io/hostname=<node>`, which has the unique value for each node.

Generate a manifest file for new pod scheduled in `node-3`, then `apply.`

```shell
$ k run pod3 --image=nginx $do > pod3.yaml
$ vi pod3.yaml
# Edit the file like following or `patch` to it
$ cat pod3.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod3
  name: pod3
spec:
  nodeSelector:
    kubernetes.io/hostname: node-3
  containers:
  - image: nginx
    name: pod3
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
$ k apply -f pod3.yaml
pod/pod3 created
$ k get po pod3 -owide
NAME   READY   STATUS    RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES
pod3   1/1     Running   0          78s   172.16.139.66   node-3   <none>           <none>
```

`pod3` is scheduled on `node-3` successfully. If there are many nodes with the same label, however, a pod would be scheduled on one of them with `nodeSelector`.&#x20;

**To schedule a pod in the exactly**, use the **`nodeName`**.

```shell
$ k run pod2 --image=httpd $do > pod2.yaml
$ vi pod2.yaml
# Edit the file like following or `patch` to it
$ cat pod2.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod2
  name: pod2
spec:
  nodeName: node-2
  containers:
  - image: httpd
    name: pod2
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
$ k apply -f pod2.yaml
pod/pod2 created
$ k get po pod2 -owide
NAME   READY   STATUS    RESTARTS   AGE   IP             NODE     NOMINATED NODE   READINESS GATES
pod2   1/1     Running   0          48s   172.16.247.9   node-2   <none>           <none>
```

Cleanup this lab.

```shell
$ k delete po --all
pod "dev" deleted
pod "pod2" deleted
pod "pod3" deleted
pod "prod" deleted
pod "test" deleted
$ k get po
No resources found in default namespace.
```

### Recap

* List objects with labels by a `--show-labels` option.
* Label to objects by a subcommand `label`.
* Filter objects by a `-l(--label)` option and selectors.
  * Two selector types are equality and set-based.
* Schedule a pod in node has some labels by `nodeSelector`.
* Schedule a pod in the specific node by `nodeName` .

### Labs

1. Run a pod with a label `tier=web` and a image `nginx`.
2. Run a pod in `node-3` by `spec.nodeName` .
3. Run a pod in `node-2` by `spec.nodeSelector` .

### Reference

* [https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
* [https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/)
