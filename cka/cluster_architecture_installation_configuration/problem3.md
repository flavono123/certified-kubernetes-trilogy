# Problem 3: Cluster Architecture, Installation, and Configuration

<details>
<summary>

Ssh into the controlplane node `node-1`. Check how the controlplane components kubelet, kube-apiserver, kube-scheduler, kube-controller-manager and etcd are started/installed on the controlplane node. Also find out the name of the DNS application and how it's started/installed on the controlplane node.
<br><br>

Write your findings into file `root@node-1:$HOME/core-components`.txt. The file should be structured like:
</summary>

kubelet: process

```sh
$ ps aux | grep kubelet
```

kube-apiserver, kube-scheduler, kube-controller-manager, etcd: static-pod

```sh
$ ls /etc/kubernetes/manifests
```

dns: pod coredns

```sh
$ k -n kube-system get pod | grep dns
$ k -n kube-system get deploy
```

```sh
$ cat <<EOF > /root/core-components.txt
kubelet: process
kube-apiserver: static-pod
kube-scheduler: static-pod
kube-controller-manager: static-pod
etcd: static-pod
dns: pod coredns
EOF
```

</details>

```sh
# root@node-1:$HOME/core-components.txt
kubelet: [TYPE]
kube-apiserver: [TYPE]
kube-scheduler: [TYPE]
kube-controller-manager: [TYPE]
etcd: [TYPE]
dns: [TYPE] [NAME]
Choices of [TYPE] are: not-installed, process, static-pod, pod
```
