# Problem 4: Cluster Architecture, Installation, and Configuration

<details>
<summary>

Create a new *ServiceAccount* `confbot` in *Namespace* `default`. Create a *Role* and *RoleBinding*, both named `confbot` as well. These should allow the new SA to only create *Secrets* and *ConfigMaps* in that *Namespace*.
</summary>

```sh
# create service account
$ k -n default create sa confbot

# create role
$ k -n default create role confbot \
  --verb=create \
  --resource=secrets,configmaps

# create role binding
$ k -n default create rolebinding confbot \
  --role=confbot \
  --serviceaccount=default:confbot # <ns>:<sa>
```

```sh
# vaildate
$ k -n default auth can-i create secrets --as=system:serviceaccount:default:confbot
yes

$ k -n default auth can-i create configmap --as=system:serviceaccount:default:confbot
yes

$ k -n default auth can-i create pods --as=system:serviceaccount:default:confbot # wrong resource
no

$ k -n default auth can-i delete secrets --as=system:serviceaccount:default:confbot # wrong verb
no

$ k -n kube-system auth can-i create secrets --as=system:serviceaccount:default:confbot # wrong ns
no
```

</details>

