# (Review) Network Policies

<details>

<summary>There was a security incident where an intruder was able to access the whole cluster from a single hacked backend Pod.
<br>
<br>To prevent this create a <i>NetworkPolicy</i> called <code>np-backend</code> in Namespace <code>spire</code>. It should allow the <code>backend</code> Pods only to:
<br>
<br>connect to <code>db</code> Pods on port 1111
<br>Use the <code>app</code> label of Pods in your policy.
<br>
<br>After implementation, connections from backend Pods to <code>vault</code> Pods on port 9999 should for example no longer work.
<br>(Run following commands to set this scenario up)
</summary>

```sh
# get IPs of pods in spire namespace
$ k -n spire get po -o wide
NAME      READY   STATUS    RESTARTS   AGE   IP             NODE     NOMINATED NODE   READINESS GATES
backend   1/1     Running   0          15m   172.16.5.48    node-2   <none>           <none>
db        1/1     Running   0          15m   172.16.5.49    node-2   <none>           <none>
vault     1/1     Running   0          15m   172.16.45.33   node-3   <none>           <none>

# test connection from backend
# to db
$ k -n spire exec -it backend -- curl -m 2 172.16.5.49:1111 # -m 2 for timeout in 2 sec
db response # works, will only allow this

# to vault
$ k -n spire exec -it backend -- curl -m 2 172.16.45.33:9999
vault response # also works, will not allow this
```

```yaml
# apply this
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-backend
  namespace: spire
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: spire
      podSelector:
        matchLabels:
          app: db
    ports:
    - protocol: TCP
      port: 1111
```

```sh
# test network policy
# to db
$ k -n spire exec -it backend -- curl -m 2 172.16.5.49:1111 # -m 2 for timeout in 2 sec
db response # should work

# to vault
$ k -n spire exec -it backend -- curl -m 2 172.16.45.33:9999
curl: (28) Connection timed out after 2001 milliseconds
command terminated with exit code 28 # should not work
```

</details>

```sh
$ k apply -f https://raw.githubusercontent.com/flavono123/certified-kubernetes-trilogy/main/resources/manifests/services_and_networking/network_policies.yaml
```
