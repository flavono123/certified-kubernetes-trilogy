# Problem 1: Troubleshooting

<details>
<summary>

Write a command into `root@node-1:$HOME/cluster_events.sh` which shows the latest events in the whole cluster, ordered by time (`metadata.creationTimestamp`). Use kubectl for it.

Now kill the kube-proxy Pod running on node `node-3` and write the events this caused into `root@node-1:$HOME/pod_kill.log`.

Finally kill the containerd container of the kube-proxy Pod on node `node-3` and write the events into `root@node-1:$HOME/container_kill.log`.

Do you notice differences in the events both actions caused?
</summary>

```sh
$ echo "kubectl get events -A --sort-by=.metadata.creationTimestamp" > /root/cluster_events.sh
$ chmod +x /root/cluster_events.sh
```

```sh
$ k -n kube-system get po -l k8s-app=kube-proxy -owide | grep node-3
# get the name of kube-proxy pod in node-3
$ k -n kube-system delete po kube-proxy-zx8q9
```

```sh
$ /root/cluster_events.sh
NAMESPACE     LAST SEEN   TYPE     REASON             OBJECT                 MESSAGE
kube-system   7s          Normal   Killing            pod/kube-proxy-zx8q9   Stopping container kube-proxy
default       5s          Normal   Starting           node/node-3
kube-system   6s          Normal   Scheduled          pod/kube-proxy-sr658   Successfully assigned kube-system/kube-proxy-sr658 to node-3
kube-system   6s          Normal   Pulled             pod/kube-proxy-sr658   Container image "registry.k8s.io/kube-proxy:v1.26.1" already present on machine
kube-system   6s          Normal   Created            pod/kube-proxy-sr658   Created container kube-proxy
kube-system   6s          Normal   Started            pod/kube-proxy-sr658   Started container kube-proxy
kube-system   6s          Normal   SuccessfulCreate   daemonset/kube-proxy   Created pod: kube-proxy-sr658
# copy above to /root/pod_kill.log
# -> Kill DaemonSet Pod will cause a new Pod to be created
```

```sh
# in node-3
$ crictl ps | grep kube-proxy
# get the container id of kube-proxy
$ crictl rm -f 0e495a5a60ae5
```

```sh
# in node-1
$ /root/cluster_events.sh
kube-system   44s         Normal   Pulled             pod/kube-proxy-sr658   Container image "registry.k8s.io/kube-proxy:v1.26.1" already present on machine
kube-system   44s         Normal   Created            pod/kube-proxy-sr658   Created container kube-proxy
kube-system   44s         Normal   Started            pod/kube-proxy-sr658   Started container kube-proxy
# copy above to /root/container_kill.log
# -> Kill container will not cause a new Pod to be created
```

</details>

