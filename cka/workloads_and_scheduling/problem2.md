# Problem 2: Workloads and Scheduling

<details>
<summary>

Do the following in *Namespace* `default`. Create a single *Pod* named `waiting-svc-ready` of image `nginx:1.16.1-alpine`. Configure a LivenessProbe which simply executes command `true`. Also configure a ReadinessProbe which does check if the url `http://svc-ready:80` is reachable, you can use `wget -T2 -O- http://svc-ready:80` for this. Start the *Pod* and confirm it isn't ready because of the ReadinessProbe.

Create a second *Pod* named `ready` of image `nginx:1.16.1-alpine` with label `id: cross-ready`. Expose the second *Pod* to a *Service* named `svc-ready`.

Now the first *Pod* should be in ready state, confirm that.
</summary>

```yaml
# apply this
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: waiting-svc-ready
  name: waiting-svc-ready
  namespace: default
spec:
  containers:
  - image: nginx:1.16.1-alpine
    name: waiting-svc-ready
    livenessProbe:
      exec:
        command:
        - "true"
    readinessProbe:
      exec:
        command:
        - sh
        - -c
        - "wget -T2 -O- http://svc-ready:80"
```

```sh
# confirm that the pod is not ready
$ k get po
NAME                READY   STATUS    RESTARTS   AGE
waiting-svc-ready   0/1     Running   0          2m

# create the second pod
$ k run ready --image=nginx:1.16.1-alpine --labels=id=cross-ready

# expose the second pod
$ k expose po ready --port=80 --target-port=80 --name=svc-ready

# confirm that the first pod is ready
$ k get po
NAME                READY   STATUS    RESTARTS   AGE
ready               1/1     Running   0          2m
waiting-svc-ready   1/1     Running   0          4m
```

</details>

