# Problem 1: Services and Networking

<details>
<summary>

*Node* `node-2` has been added to the cluster using kubeadm and TLS bootstrapping.

Find the "Issuer" and "Extended Key Usage" values of the `node-2`:

kubelet **client** certificate, the one used for outgoing connections to the kube-apiserver.
kubelet **server** certificate, the one used for incoming connections from the kube-apiserver.
Write the information into file `root@node-1$HOME/cert-info.txt`.

Compare the "Issuer" and "Extended Key Usage" fields of both certificates and make sense of these.
</summary>

```sh
# your local
$ gcloud compute ssh node-2

# node-2 as root
$ systemctl cat kubelet

# check kubeconfig path -> /etc/kubernetes/kubelet.conf
# check cert path from kubeconfig for kubelet -> /var/lib/kubelet/pki/kubelet-client-current.pem

# client cert
$ openssl x509  -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem

# server cert
$ openssl x509  -noout -text -in /var/lib/kubelet/pki/kubelet.crt
```

```sh
# Client Certificate
$ echo "Issuer: kubernetes" >> ~/cert-info.txt
$ echo "Extended Key Usage: TLS Web Client Authentication" >> ~/cert-info.txt

# Server Certificate
$ echo "Issuer: node-1-ca@1680886607" >> ~/cert-info.txt
$ echo "Extended Key Usage: TLS Web Server Authentication" >> ~/cert-info.txt
```

</details>

