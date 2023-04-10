# Problem 3: Workloads and Scheduling

<details>
<summary>

Create a *Pod* named `certified` in new *Namespace* `foudation` with three containers, named `admin`, `developer` and `specailist`. There should be a volume attached to that *Pod* and mounted into every container, but the volume shouldn't be persisted or shared with other Pods.

Container `admin` should be of image `nginx:1.17.6-alpine` and have the name of the node where its Pod is running available as environment variable `HOSTNAME_SCHEDULED`.

Container `developer` should be of image `busybox:1.31.1` and write the output of the date command every second in the shared volume into file date.log. You can use `while true; do date >> /your/vol/path/date.log; sleep 1; done` for this.

Container `specialist` should be of image `busybox:1.31.1` and constantly send the content of file `date.log` from the shared volume to stdout. You can use `tail -f /your/vol/path/date.log` for this.

Check the logs of container `specialist` to confirm correct setup.
</summary>

```sh
# create namespace
$ k create ns foudation
```

```yaml
# apply this
apiVersion: v1
kind: Pod
metadata:
  name: certified
  namespace: foudation
spec:
  containers:
  - name: admin
    image: nginx:1.17.6-alpine
    env:
    - name: HOSTNAME_SCHEDULED
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
  - name: developer
    image: busybox:1.31.1
    volumeMounts:
    - name: shared-vol
      mountPath: /tmp/vol
    command:
    - sh
    - -c
    - "while true; do date >> /tmp/vol/date.log; sleep 1; done"
  - name: specialist
    image: busybox:1.31.1
    volumeMounts:
    - name: shared-vol
      mountPath: /tmp/vol
    command:
    - sh
    - -c
    - "tail -f /tmp/vol/date.log"
  volumes:
  - name: shared-vol
    emptyDir: {}
```

\* `env.valueFrom.fieldRef.fieldPath`: https://kubernetes.io/ko/docs/tasks/inject-data-application/environment-variable-expose-pod-information/#%ED%8C%8C%EB%93%9C-%ED%95%84%EB%93%9C%EB%A5%BC-%ED%99%98%EA%B2%BD-%EB%B3%80%EC%88%98%EC%9D%98-%EA%B0%92%EC%9C%BC%EB%A1%9C-%EC%82%AC%EC%9A%A9%ED%95%98%EC%9E%90

```sh
# check env of container admin
$ k exec -n foudation certified -c admin -- printenv HOSTNAME_SCHEDULED

# check logs of container specialist
$ k logs -n foudation certified -c specialist
```

</details>

