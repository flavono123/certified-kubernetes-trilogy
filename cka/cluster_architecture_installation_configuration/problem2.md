# Problem 2: Cluster Architecture, Installation, and Configuration

<details>
<summary>

Check how long the kube-apiserver server certificate is valid on `node-1`. Do this with openssl or cfssl. Write the exipiration date into `root@node-1:$HOME/expiration.txt`.
<br><br>

Also run the correct `kubeadm` command to list the expiration dates and confirm both methods show the same date.
<br><br>

Write the correct `kubeadm` command that would renew the apiserver server certificate into `root@node-1:$HOME/kubeadm-renew-certs.sh`.
</summary>

```sh
$ openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate > ~/expiration.txt

$ echo "kubeadm certs renew apiserver" > ~/kubeadm-renew-certs.sh
$ chmod +x ~/kubeadm-renew-certs.sh # to check if the command is correct
```

</details>

