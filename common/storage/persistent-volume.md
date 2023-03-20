# Persistent Volume

Unlike volumes in the previous chapter, whose lifecycle goes with the mounted Pods, Persistent Volumes are provisioned as individual storage resources of a cluster.

You can create one as a kubernetes object.

```bash
$ cat <<EOF > pv-pv1.yaml
> apiVersion: v1
> kind: PersistentVolume
> metadata:
>   name: pv1
> spec:
>   capacity:
>     storage: 100Mi
>   accessModes:
>     - ReadWriteOnce
>   persistentVolumeReclaimPolicy: Retain
>   hostPath:
>     path: /tmp/pv1
> EOF
```

#### Persistent Volume

There is no option for `create` subcommand to create a Persistent Volume. Have you remember all the specification for PV, like above?

No, **you can reference the official docs of Kubernetes in exams.** Just copy that from the pages for [concepts](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) or check the [API references](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/).

Some fields for PV have following options:

* `.spec.capacity.storage` :  The storage quantity of PV
* `.spec.accessModes`
  * `ReadWriteOnce` : The volume can be mounted as read/write by single node.
  * `ReadOnlyMany` : The volume can be mounted as read-only by many nodes.
  * `ReadWriteMany` : The volume can be mounted as read/write by many nodes.
  * `ReadWriteOncePod` : The volume can be mounted as read-write by a single Pod.
* `.spec.persistentVolumeReclaimPolicy`
  * `Retain` : Manual reclamation(Just release it).
  * `Delete` : Delete with the associated storage asset.
  * `Recycle` (deprecated): Do a basic scrub(`rm -rf /<volume>/*`) to reuse.

After create the PV, you can see it is available. Access modes are printed in abbreviations.

```bash
$ k apply -f pv-pv1.yaml
persistentvolume/pv1 created
# Abbreviations in ACCESS MODES
# RWO - ReadWriteOnce
# ROX - ReadOnlyMany
# RWX - ReadWriteMany
# RWOP - ReadWriteOncePod
$ k get pv
NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pv1    100Mi      RWO            Retain           Available                                   4s
```

#### Persistent Volume Claim

To use a PV in a Pod, another object is required, named PersistentVolumeClaim. It binds PV to itself to use a volume.

```bash
$ cat <<EOF > pvc-50m.yaml
> apiVersion: v1
> kind: PersistentVolumeClaim
> metadata:
>   name: pvc-50m
>   namespace: default
> spec:
>   accessModes:
>   - ReadWriteOnce
>   resources:
>     requests:
>       storage: 50Mi
> EOF
$ k apply -f pvc-50m.yaml


```

The specifications for PVCs also can be referenced in the docs like PV's one. To bind a PV, some conditions must be matched for a PVC.

* If access modes of the PV are matched.
* If a PV has sufficient storage quantities for requests of the PVC(equal or greater than).
* Always bind to a PV 1:1.&#x20;

You specify the access modes as `ReadWriteOnce` and the request of resources as `50Mi` under the PV's storage(`100Mi`). And the status of PV is available now, the PVC would bind to that when you create it.

```bash
$ k apply -f pvc-50m.yaml
persistentvolumeclaim/pvc-50m created
$ k get pvc
NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-50m   Bound    pv1      100Mi      RWO                           2s
$ k get pv
NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   REASON   AGE
pv1    100Mi      RWO            Retain           Bound    default/pvc-50m                           78m
```

Also check for the status of PV changed in `Bound`.

#### Mount Persistent Volumes in Pods

You can run a Pod that mount the PV.

```bash
$ k run pv --image=busybox $do --command sleep -- 1d  > pod-pv.yaml
$ vi pod-pv.yaml
$ cat pod-pv.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pv
  name: pv
spec:
  containers:
  - command:
    - sleep
    - 1d
    image: busybox
    name: pv
    volumeMounts:
    - mountPath: /var
      name: pvc
    resources: {}
  volumes:
  - name: pvc
    persistentVolumeClaim:
      claimName: pvc-50m
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
$ k apply -f pod-pv.yaml
pod/pv created
$ k get po -owide
NAME   READY   STATUS    RESTARTS   AGE     IP            NODE     NOMINATED NODE   READINESS GATES
pv     1/1     Running   0          6s      172.16.2.10   node-3   <none>           <none>
$ k exec -it pv -- sh
/ # echo "Here is the persistent volume" > /var/footprint
/ # exit

```

You can mount the PV as a volume all the same way in the previous chapters, except specifying the volume at `.spec.volumes[].persistentVolumeClaim.claimName`.&#x20;

You can check the footprinting at the `node-3` , in this case, where the PV exists(It also same to where the Pod is running since its type is `hostPath`).

```bash
# in the host, attach to node-3 via `vagrant ssh node-3`[V
vagrant@node-3:~$ cat /tmp/pv1/footprint
Here is the persistent volume
```

What will be happen to PV and PVC if you delete the Pod?

```bash
$ k delete po pv
pod "pv" deleted
$ k get po,pvc,pv
NAME                            STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/pvc-50m   Bound    pv1      100Mi      RWO                           44m

NAME                   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   REASON   AGE
persistentvolume/pv1   100Mi      RWO            Retain           Bound    default/pvc-50m                           122m
```

The PV and PVC are exists even the Pod is destroyed since their lifecycle is independent from the Pod's. What for deleting the PVC?

```bash
$ k delete pvc pvc-50m
persistentvolumeclaim "pvc-50m" deleted
$ k get pvc,pv
NAME                   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM             STORAGECLASS   REASON   AGE
persistentvolume/pv1   100Mi      RWO            Retain           Released   default/pvc-50m                           125m
```

The PV is still remained in "release" status(not "available") since its reclaim policy is `Retain` . The real storage of that is not deleted.

```
vagrant@node-3:~$ cat /tmp/pv1/footprint
Here is the persistent volume
```

### Recap

* Persistent Volumes are provisioned as storage objects for the Kuberenetes clsuter. It has its own lifecycle not concerned with the mounted Pod.
* Persistent Volume Claims bind PVs if the conditions matched.&#x20;

### Labs



### References

* [https://kubernetes.io/docs/concepts/storage/persistent-volumes/](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
* [https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/)
