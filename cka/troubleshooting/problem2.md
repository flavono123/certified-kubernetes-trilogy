# Problem 2: Troubleshooting

<details>
<summary>

In *Namespace* `default` create a *Pod* named `maelstrom` of image `httpd:2.4.41-alpine` whose resource requests for `10m` CPU and `20Mi` memory. Find out on which node the Pod is scheduled. Ssh into that node and find the containerd container belonging to that Pod.

Using command crictl:

Write the ID of the container and the `info.runtimeType` into `root@node-1:$HOME/pod-container.txt`
Write the logs of the container into `root@node-1:$HOME/pod-container.log`
</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: maelstrom
  namespace: default
spec:
  containers:
  - name: maelstrom
    image: httpd:2.4.41-alpine
    resources:
      requests:
        cpu: 10m
        memory: 20Mi
```

```sh
$ k get po -owide
NAME             READY   STATUS    RESTARTS   AGE    IP             NODE     NOMINATED NODE   READINESS GATES
maelstrom        1/1     Running   0          11s    172.16.45.34   node-3   <none>           <none>
```

```sh
# node-3
$ crictl ps | grep maelstrom
e187c4be91f14       54b0995a63052       32 seconds ago      Running             maelstrom                   0                   ce5401f86e68f       maelstrom

$ crictl inspect e187c4be91f14 | grep -i runtimetype
    "runtimeType": "io.containerd.runc.v2",

$ crictl logs e187c4be91f14
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.16.45.34. Set the 'ServerName' directive globally to suppress this message
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.16.45.34. Set the 'ServerName' directive globally to suppress this message
[Mon Apr 10 19:20:35.424876 2023] [mpm_event:notice] [pid 1:tid 139796448959816] AH00489: Apache/2.4.41 (Unix) configured -- resuming normal operations
[Mon Apr 10 19:20:35.425221 2023] [core:notice] [pid 1:tid 139796448959816] AH00094: Command line: 'httpd -D FOREGROUND'
# copy above to root@node-1:$HOME/pod-container.log
```

```sh
# node-1
$ echo "e187c4be91f14 io.containerd.runc.v" > /root/pod-container.txt

$ cat /root/pod-container.log
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.16.45.34. Set the 'ServerName' directive globally to suppress this message
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.16.45.34. Set the 'ServerName' directive globally to suppress this message
[Mon Apr 10 19:20:35.424876 2023] [mpm_event:notice] [pid 1:tid 139796448959816] AH00489: Apache/2.4.41 (Unix) configured -- resuming normal operations
[Mon Apr 10 19:20:35.425221 2023] [core:notice] [pid 1:tid 139796448959816] AH00094: Command line: 'httpd -D FOREGROUND'
```

</details>

