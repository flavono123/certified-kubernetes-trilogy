# Cluster Role and Cluster Rolebinding

## ClusterRole과 ClusterRoleBinding
ClusterRole과 ClusterRoleBinding은 Role과 RoleBinding과 유사하지만, 클러스터 전체에 적용되는 리소스가 대상입니다.

클러스터 전체에 적용되는 리소스는 크게 구다지로 구분할 수 있습니다.
-  `node`, `namespace` 같은 클러스터 수준(cluster-scoped)의 리소스
-  모든 네임스페이스에 대한 네임스페이스(namespace-scoped) 리소스(e.g. `*/pod`, `*/service`)

### 클러스터 수준 리소스에 대한 권한
클러스터 수준 리소스는 다음 명령으로 확인할 수 있습니다. 즉 네임스페이스 리소스가 아니면 클러스터 수준 리소스라고 할 수 있습니다.

```sh
$ k api-resources --namespaced=false
NAME                              SHORTNAMES                             APIVERSION                             NAMESPACED   KIND
componentstatuses                 cs                                     v1                                     false        ComponentStatus
namespaces                        ns                                     v1                                     false        Namespace
nodes                             no                                     v1                                     false        Node
...
```

추가한 사용자에게 `node`에 대한 조회 권한을 만들어 보겠습니다. 적용 대상과 범위만 다르기 때문에 Role, RoleBinding과 생성 방법, 매니페스트 구조는 거의 동일합니다.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-nodes
subjects:
- kind: User
  name: flavono123
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

위 매니페스트를 적용하거나 아래 명령으로 생성합니다.

```sh
# 작업 전 어드민 컨텍스트인지 확인
# k config current-context => kubernetes-admin@kubernetes
$ k create clusterrole node-reader \
  --verb=get,list,watch \
  --resource=nodes
clusterrole.rbac.authorization.k8s.io/node-reader created

$ k create clusterrolebinding read-nodes \
  --clusterrole=node-reader \
  --user=flavono123
clusterrolebinding.rbac.authorization.k8s.io/read-nodes created
```

추가한 사용자로 노드도 조회가 가능합니다.
```sh
$ k config use-context flavono123@kubernetes
Switched to context "flavono123@kubernetes".

$ k -n kube-system get no # 권한 오류가 나면 안된다.
```


### 네임스페이스 리소스의 모든 네임스페이스에 대한 권한

네임스페이스 리소스 역시 ClusterRole에서 정의할 수 있습니다. ClusterRole의 네임스페이스를 지정할 필요가 없고 `rules[].resouces`의 네임스페이스 리소스의 모든 네임스페이스에 대한 권한을 지정합니다.

다음은 모든 네임스페이스의 파드에 대한 조회 권한을 추가한 예입니다.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods
subjects:
- kind: User
  name: flavono123
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```sh
# 작업 전 어드민 컨텍스트인지 확인
# k config current-context => kubernetes-admin@kubernetes
$ k create clusterrole pod-reader \
  --verb=get,list,watch \
  --resource=pods
clusterrole.rbac.authorization.k8s.io/pod-reader created

$ k create clusterrolebinding read-pods \
  --clusterrole=pod-reader \
  --user=flavono123
clusterrolebinding.rbac.authorization.k8s.io/read-pods created
```

이제 추가한 사용자로 `default` 네임스페이스가 아닌, 다른 네임스페이스의 파드도 조회가 가능합니다.

```sh
$ k config use-context flavono123@kubernetes
Switched to context "flavono123@kubernetes".

$ k -n kube-system get pods # 권한 오류가 나면 안된다.
```

### ClusterRole과 RoleBinding
RoleBinding은 ClusterRole을 참조할 수 있습니다. 즉 ClusterRole과 RoleBinding 조합이 가능합니다. 이렇게하면 권한이 적용되는 리소스는 RoleBinding의 네임스페이스로 제한됩니다.

ClusterRole과 RoleBinding의 참조 예제를 만들기 위해, 전에 만든 ClusterRoleBinding `read-pods`를 삭제하고 `default` 네임스페이스에 새로운 RoleBinding을 만들어 보겠습니다.

```sh
# clusterrolebinding read-pods 삭제
$ k delete clusterrolebinding read-pods
clusterrolebinding.rbac.authorization.k8s.io "read-pods" deleted

# clusterrole을 참조하는 rolebinding 생성
$ k create rolebinding read-default-pods \
  --clusterrole=pod-reader \
  --user=flavono123
rolebinding.rbac.authorization.k8s.io/read-default-pods created

# flavono123 컨텍스트로 변경
$ k config use-context flavono123@kubernetes
Switched to context "flavono123@kubernetes".

$ k -n default get pods
No resources found in default namespace.
$ k -n kube-system get pods
Error from server (Forbidden): pods is forbidden: User "flavono123" cannot list resource "pods" in API group "" in the namespace "kube-system"
```

`default` 네임스페이스의 파드는 조회가 가능하지만, `kube-system` 네임스페이스의 파드는 조회가 불가능합니다. 이러면 `default` 네임스페이스의 파드 조회 Role을 참조하는 것과 무엇이 다를까요?

**ClusterRole과 RoleBinding을 일대다로 참조하면 사용하면 매번 네임스페이스 리소스에 대한 Role을 만들 필요가 없습니다.** 네임스페이스 리소스에 대한 ClusterRole을 만들고 네임스페이스 마다 RoleBinding을 만들면 적은 RBAC 객체로 네임스페이스 리소스 권한을 관리할 수 있습니다.

## `auth can-i`

`kubectl auth can-i`는 주체가 특정 작업을 수행할 수 있는지 확인하는 명령입니다. RBAC을 생성, 수정하면서 컨텍스트를 바꾸지 않고 `--as` 옵션으로 주체를 지정하여 권한 여부를 확인할 수 있습니다.

```sh
$ k -n default auth can-i get pods --as flavono123
yes

$ k -n kube-system auth can-i get pods --as flavono123
no
```
이 때 네임스페이스 플래그 `-n`은 권한 대상 리소스를 특정하는데 사용됩니다. 그리고 `--as`의 주체로 서비스 어카운트도 사용할 수 있습니다.

```sh
$ k -n default auth can-i get pods --as system:serviceaccount:default:default
```

<details>
<summary>Q1. <code>ns1</code>, <code>ns2</code> 두개의 네임스페이스를 만들고 ReplicaSet 삭제 권한을 <code>flavono123</code> 사용자에게 주세요.</summary>

```sh
# 네임스페이스 생성
$ k create ns ns1
$ k create ns ns2
```

```sh
# 1. Role과 RoleBinding 사용
$ k -n ns1 create role rs-cleaner \
  --verb=delete \
  --resource=replicasets

$ k -n ns1 create rolebinding delete-rs \
  --role=rs-cleaner \
  --user=flavono123

$ k -n ns2 create role rs-cleaner \
  --verb=delete \
  --resource=replicasets

$ k -n ns2 create rolebinding delete-rs \
  --role=rs-cleaner \
  --user=flavono123
```

또는

```sh
# 2. ClusterRole과 RoleBinding 사용
$ k create clusterrole rs-cleaner\
  --verb=delete \
  --resource=replicasets

$ k -n ns1 create rolebinding delete-rs \
  --clusterrole=rs-delete \
  --user=flavono123

$ k -n ns2 create rolebinding delete-rs \
  --clusterrole=rs-delete \
  --user=flavono123
```

확인

```sh
$ k -n ns1 auth can-i delete replicasets --as flavono123
$ k -n ns2 auth can-i delete replicasets --as flavono123
$ k -n ns1 auth can-i get replicasets --as flavono123 # 다른 동작 권한이 없어야 함
$ k -n ns1 auth can-i get deploy --as flavono123 # 다른 리소스에 권한이 없어야 함
$ k -n default auth can-i delete replicasets --as flavono123 # 다른 네임스페이스 권한이 없어야 함
```

</details>

---

### 참고
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
