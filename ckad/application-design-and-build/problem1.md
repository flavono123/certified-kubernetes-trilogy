<details>
<summary>

Create a new *PersistentVolume* named `ckad-pv`. It should have a capacity of *2Gi*, accessMode *ReadWriteOnce*, hostPath `/Volumes/Data` and no storageClassName defined.

Next create a new PersistentVolumeClaim in Namespace `default` named `ckad-pvc` . It should request *2Gi* storage, accessMode *ReadWriteOnce* and should not define a storageClassName. The *PVC* should bound to the *PV* correctly.

Finally create a new *Deployment* `ckad-deploy` in Namespace `default` which mounts that volume at `/tmp/ckad-data`. The *Pods* of that *Deployment* should be of image `httpd:2.4.41-alpine`.

</summary>


</details>
