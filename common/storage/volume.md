# Volume

A Pod can mount a volume as a directory which its Containers are accessible.

Volumes are specified in `.spec.volumes` in Pods and mounted  into containers in `.spec.containers[*].volumeMounts` , matching theirs name, like below.

```shell
$ k run vol --image=busybox $do  > pod-vol.yaml
$ vi pod-vol.yaml
# Edit 
# - `.spec.containers[0].command`
# - `.spec.containers[0].volumeMounts`
# - `.spec.volumes`
# like below
$ cat pod-vol.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: vol
  name: vol
spec:
  containers:
  - image: busybox
    name: vol
    command:
    - /bin/sh
    - -c
    - while :;
      do
        echo -n "written in vol:";
        cat /vol/data;
        sleep 1;
      done
    volumeMounts:
    - name: emptydir
      mountPath: /vol
    resources: {}
  volumes:
  - name: emptydir
    emptyDir: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
$ k apply -f pod-vol.yaml
pod/vol created
```

#### EmptyDir

`emptyDir` is a type of ephemeral volumes which are removed when a Pod is killed. The container would print the '/vol/data' repeatedly. Check the logs.

```bash
$ k logs -f vol
written in vol:cat: can't open '/vol/data': No such file or directory
written in vol:cat: can't open '/vol/data': No such file or directory
written in vol:cat: can't open '/vol/data': No such file or directory
^C

```

You can see errors since the '/vol/data' is not exists.

Create the '/vol/data' and check the logs again.

```bash
$ k exec -it vol -- sh
/ # echo "Start K8s with CKT" > /vol/data
/ # exit
$ k logs --tail 5 vol
written in vol:Start K8s with CKT
written in vol:Start K8s with CKT
written in vol:Start K8s with CKT

```

It print the file you just created now. It would be removed if a Pod is dead since it's in an ephemeral volume.

<pre class="language-bash"><code class="lang-bash">$ k delete -f pod-vol.yaml &#x26;&#x26; k apply -f pod-vol.yaml
pod "vol" deleted
pod/vol created
<strong>$ k logs -f vol
</strong>written in vol:cat: can't open '/vol/data': No such file or directory
written in vol:cat: can't open '/vol/data': No such file or directory
written in vol:cat: can't open '/vol/data': No such file or directory
^C
</code></pre>

#### HostPath

You can mount to the file system of the Node where the Pod is running with a volume type `hostPath`.

Edit and apply the previous Pod like below.

```bash
$ vi pod-vol.yaml
# Edit 
# - `.spec.containers[0].command`
# - `.spec.containers[0].volumeMounts`
# - `.spec.volumes`
# like below
$ cat pod-vol.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: vol
  name: vol
spec:
  containers:
  - image: busybox
    name: vol
    command:
    - /bin/sh
    - -c
    - while :;
      do
        echo -n "I'm in ";
        cat /node-etc/hostname;
        sleep 1;
      done
    volumeMounts:
    - name: hostpath
      mountPath: /node-etc
    resources: {}
  volumes:
  - name: hostpath
    hostPath:
      path: /etc
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
$ k delete -f pod-vol.yaml && k apply -f pod-vol.yaml
pod "vol" deleted
pod/vol created
$ k get po -owide
NAME   READY   STATUS    RESTARTS   AGE   IP           NODE     NOMINATED NODE   READINESS GATES
vol    1/1     Running   0          24s   172.16.2.9   node-3   <none>           <none>
$ k logs -f vol
I'm in node-3
I'm in node-3
I'm in node-3
^C
```

You can see the container can access to the Node's directory. But `hostPath` is not a good way as a volume:

* Pods are not guaranteed to be scheduled in which nodes.
* It exposes the node's path like '/etc'. :scream:

More 'persistent' volumes are required. We will cover this next.

Cleanup the labs

```bash
$ k delete po vol
pod "vol" deleted
```

### Recap

* Volumes are defined and mounted through fields of Pods, `.spec.volumes`  and `.spec.containers[*].volumeMounts`.
* Mounted volumes are shared to containers in a Pod.
* `emptyDir` is an ephemeral type volume.
* `hostPath` uses a directory of a Node where a Pod is scheduled.

### Labs

### References

* [https://kubernetes.io/docs/concepts/storage/volumes/](https://kubernetes.io/docs/concepts/storage/volumes/)
