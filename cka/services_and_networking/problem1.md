# Problem 1: Services and Networking

<details>
<summary>
You're ask to find out following information about the cluster

- What is the Service CIDR?
- What is the Pod CIDR?

Write your answers into file `root@node1:$HOME/cluster-info`, structured like this:

```sh
#/root/cluster-info
Service CIDR: [ANSWER]
Pod CIDR: [ANSWER]
```
</summary>

\* Service CIDR 참고: https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/

\* Pod CIDR 참고: https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/

```sh
# Service CIDR
$ cat /etc/kubernetes/manifests/kube-apiserver.yaml | yq .spec.containers[0].command | grep service-cluster-ip-range

# Pod CIDR
$ cat /etc/kubernetes/manifests/kube-controller-manager.yaml | yq .spec.containers[0].command | grep cluster-cidr
```

```sh
$ cat <<EOF > /root/cluster-info
Service CIDR: 10.96.0.0/12
Pod CIDR: 172.16.0.0/16
```

</details>
