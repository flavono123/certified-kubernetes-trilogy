# Secrets

Secrets are very similar with ConfigMaps except it deals the credential data.

There are some types for Secrets.

* `docker-registry`
* `tls`
* `generic`

`docker-registry` and `tls` are for special purposes. We just discuss about the `generic` type, literally general configurations to be encrypted.

Create the Secret first.

```shell
$ k create secret generic cred \
  --from-literal PASSWORD=secret-magic \
  --from-literal TOKEN=1234-5678
secret/cred created
$ k get secret cred -oyaml
apiVersion: v1
data:
  PASSWORD: c2VjcmV0LW1hZ2lj
  TOKEN: MTIzNC01Njc4
kind: Secret
metadata:
  creationTimestamp: "2022-11-22T15:27:02Z"
  name: cred
  namespace: default
  resourceVersion: "156143"
  uid: 8512c057-ff6a-4d40-899a-b63757b64ff3
type: Opaque
```

The command is also similar with ConfigMap's one except the type `generic` added. In `.data` field of the Secret object, the values are not we wrote, however. It just encoded in base64.

```shell
# Remove trailing new line with an option `-n`
$ echo -n "c2VjcmV0LW1hZ2lj" | base64 -d
secret-magicroot$ # <enter> <- This is a prompt. Notice that the origin credential has no new line.
$ echo -n "MTIzNC01Njc4" | base64 -d
1234-5678$

```

Notice that **the base64 encoding is not the encryption**. It just for convenient way to deal various type of characters in credentials as simple. Credentials in Secrets are encrypted in ETCD, the cluster component stores all its data, and decrypted accordingly when they are used.

To check that, we just run a Pod, echoing the environment variables, used in the lab of ConfigMap.

```shell
$ k run echo-secret --image=busybox \
  --restart=Never \
  $do \
  --command /bin/echo \
  -- '$(PASSWORD)' '$(TOKEN)' > pod-echo-secret..yaml
$ vi pod-echo-secret.yaml
# Edit `.spec.containers[0].envFrom`(!) like below
$ cat pod-echo-secret.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: echo-secret
  name: echo-secret
spec:
  containers:
  - command:
    - /bin/echo
    - $(PASSWORD)
    - $(TOKEN)
    image: busybox
    name: echo-secret
    resources: {}
    envFrom:
    - secretRef:
        name: cred
  dnsPolicy: ClusterFirst
  restartPolicy: Never
status: {}
$ k apply -f pod-echo-secret.yaml
pod/echo created
$ k logs -f echo-secret
secret-magic 1234-5678
```

The environment variables are printed well in decrypted and also decoded(base64).

Have you notice the difference from configuring environment variables from a ConfigMap? In this lab, we used a `.spec.envFrom` field (not a `.spec.env`) and reference the whole Secret. Then, keys and values are configured to names and values of environment variables respectively.

So, this part.

```yaml
spec:
  containers:
    envFrom:
    - secretRef:
        name: cred
```

Is same to following

```yaml
spec:
  containers:
    env:
    - name: PASSWORD
      valueFrom:
        secretKeyRef:
          name: cred
          key: PASSWORD
    - name: TOKEN
      valueFrom:
        secretKeyRef:
          name: cred
          key: TOKEN
```

This is also for configuring ConfigMaps.

Cleanup the labs.

```bash
$ k delete secret cred
secret "cred" deleted
$ k delete po echo-secret
pod "echo" deleted
$ k get secret,po
No resources found in default namespace.
$ rm pod-echo-secret.yaml
```

### Recap

* Secrets is ConfigMaps for credentials in general.
* In `.data` field of Secret objects, the values are encoded in base64.
  * The base64 encoding is not the encryption.
* Secrets and ConfigMaps can be referenced in 2 ways from containers of Pods.
  * `.spec.env` : Referencing each key in Secrets/ConfigMaps respectively.
  * `.spec.envFrom`: Referencing the whole Secret/ConfigMap data key-value pairs to names and values of environment variables for each.

### Labs

### References

* [https://kubernetes.io/docs/concepts/configuration/secret/](https://kubernetes.io/docs/concepts/configuration/secret/)
