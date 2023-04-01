# Role and Rolebinding

## 쿠버네티스 인가
쿠버네티스는 클러스터 내에서의 접근을 제어하기 위해 인가(Authorization) 모델이 있습니다. 즉 API 요청 시 인증된 사용자가 요청한 작업을 수행할 수 있는 권한이 있는지 확인하는 것입니다.

API 요청에는 다음 속성이 있습니다:
- 보안 주체(subject)
  - User
  - Group
- 객체 자원
  - Resource
  - API group
  - Namespace


## RBAC
RBAC(Role-Based Access Control)은 인가 모델 중 하나입니다. 이 모델은 Role과 RoleBinding 객체를 사용하여 사용자나 그룹에 대한 권한을 관리합니다.

API 서버 실행 옵션에서 인가 모드를 확인할 수 있습니다.

```sh
$ cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep authorization-mode
    - --authorization-mode=Node,RBAC
```

쿠버네티스는 RBAC 인가 모델을 구현하기 위한 객체, `Role`과 `RoleBinding`이 있습니다.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: flavono123
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

위 Role `pod-reader`는 `default` 네임스페이스에서 `pods` 리소스에 대한 `get`, `watch`, `list` 권한을 가지고 있습니다.

그리고 RoleBinding `read-pods`는 앞선 Kubeconfig장에서 만든 `flavono123` 사용자에게 `pod-reader` Role을 바인딩합니다.

위 매니페스트를 적용하거나 kubectl create으로 같은 Role, RoleBinding을 만들 수 있습니다.

```sh
$ k -n default create role pod-reader \
  --verb=get \
  --verb=list \
  --verb=watch \
  --resource=pods # apiGroup은 리소스에 따라 지정됨
role.rbac.authorization.k8s.io/pod-reader created

$ k -n default create rolebinding read-pods \
  --role=pod-reader \
  --user=flavono123
rolebinding.rbac.authorization.k8s.io/read-pods created

# 확인
$ k -n default get role,rolebinding
NAME                                        CREATED AT
role.rbac.authorization.k8s.io/pod-reader   2023-04-01T08:26:42Z

NAME                                              ROLE              AGE
rolebinding.rbac.authorization.k8s.io/read-pods   Role/pod-reader   20s
```

Role과 RoleBinding은 네임스페이스 객체이므로 네임스페이스를 지정해야 합니다.

kubeconfig 컨텍스트를 사용자 `flavono123`로 바꿔 `default` 네임스페이스에 파드 목록 요청을 해봅니다.
```sh
$ k config use-context flavono123@kubernetes
Switched to context "flavono123@kubernetes".

$ k get po
No resources found in default namespace.
```

위에서 만든 Role, RoleBinding으로 인가되어 (파드는 없지만) 요청이 성공했습니다. 하지만 다른 객체에 대한 요청은 실패합니다.

```sh
$ k get ns
Error from server (Forbidden): namespaces is forbidden: User "flavono123" cannot list resource "namespaces" in API group "" at the cluster scope

$ k get deploy
Error from server (Forbidden): deployments.apps is forbidden: User "flavono123" cannot list resource "deployments" in API group "apps" in the namespace "default"
```

원래 컨텍스트로 돌아옵니다.
```sh
$ k config use-context kubernetes-admin@kubernetes
```

<details>
<summary>Q1. 추가한 사용자에 대해 <code>default</code> 네임스페이스의 파드 생성 권한이 있는 Role과 RoleBinding을 만들어보세요.</summary>

```sh
$ k -n default create role pod-creator \
  --verb=create \
  --resource=pods

$ k -n default create rolebinding create-pods \
  --role=pod-creator \
  --user=flavono123
```

또는 다음 매니페스트 적용

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-creator
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: create-pods
  namespace: default
subjects:
- kind: User
  name: flavono123
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-creator
  apiGroup: rbac.authorization.k8s.io
```

검증

```sh
$ k config use-context flavono123@kubernetes
$ k -n default run nginx --image=nginx # 파드 생성이 성공해야 함
```

</details>

<details>
<summary>Q2. 다음 스펙의 Role과 RoleBinding을 만들어 보세요.
<br>1. Role(이름): <code>deploy-all</code>
<br>- 네임스페이스: <code>default</code>
<br>- 리소스: <code>deployments</code>
<br>- 권한: 모든 권한
<br>2. RoleBinding: <code>admin-deploy</code>
<br>- Role 참조: <code>deploy-all</code>
<br>- 서비스 어카운트(주체): <code>default</code>(system:serviceaccount:default:default)
</summary>

```sh
$ k -n default create role deploy-all \
  --verb=* \
  --resource=deployments

$ k -n default create rolebinding admin-deploy \
  --role=deploy-all \
  --serviceaccount=default:default
```

또는 다음 매니페스트 적용

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deploy-all
  namespace: default
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: admin-deploy
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deploy-all
subjects:
- kind: ServiceAccount
  name: default
  namespace: default
```

검증

```sh
$ k auth can-i --as system:serviceaccount:default:default create deploy
# auth can-i 명령은 다음 장에서 설명합니다.
```

---

### 참고
- [인가 개요](https://kubernetes.io/ko/docs/reference/access-authn-authz/authorization)
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
