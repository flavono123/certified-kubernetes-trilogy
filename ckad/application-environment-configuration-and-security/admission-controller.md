# Admission Controllers

어드미션 컨트롤러는 쿠버네티스 API 서버가 클러스터에 대한 요청을 수신할 때 실행되는 플러그인입니다. 어드미션 컨트롤러는 요청을 수신하고, 수정하거나, 거부하는데 사용됩니다. 어드미션 컨트롤러는 클러스터 관리자가 클러스터를 보호하고, 사용자가 클러스터를 사용할 수 있도록 도와줍니다.

어드미션 컨트롤러는 앞서 배운 인증과 인가 과정 뒤에 실행됩니다. 즉 인증과 인가 과정을 통과한 요청만 어드미션 컨트롤러에 의해 처리됩니다.

어드미션 컨트롤러 목록은 `kube-apiserver` 옵션에서 확인할 수 있습니다.

```sh
$ k -n kube-system exec -it kube-apiserver-node-1 -- kube-apiserver -h | grep enable-admission
...
--enable-admission-plugins strings       admission plugins that should be enabled in addition to default enabled ones (NamespaceLifecycle, LimitRanger, ServiceAccount, TaintNodesByCondition, PodSecurity, Priority, DefaultTolerationSeconds, DefaultStorageClass, StorageObjectInUseProtection, PersistentVolumeClaimResize, RuntimeClass, CertificateApproval, CertificateSigning, CertificateSubjectRestriction, DefaultIngressClass, MutatingAdmissionWebhook, ValidatingAdmissionPolicy, ValidatingAdmissionWebhook, ResourceQuota). Comma-delimited list of admission plugins: AlwaysAdmit, AlwaysDeny, AlwaysPullImages, CertificateApproval, CertificateSigning, CertificateSubjectRestriction, DefaultIngressClass, DefaultStorageClass, DefaultTolerationSeconds, DenyServiceExternalIPs, EventRateLimit, ExtendedResourceToleration, ImagePolicyWebhook, LimitPodHardAntiAffinityTopology, LimitRanger, MutatingAdmissionWebhook, NamespaceAutoProvision, NamespaceExists, NamespaceLifecycle, NodeRestriction, OwnerReferencesPermissionEnforcement, PersistentVolumeClaimResize, PersistentVolumeLabel, PodNodeSelector, PodSecurity, PodTolerationRestriction, Priority, ResourceQuota, RuntimeClass, SecurityContextDeny, ServiceAccount, StorageObjectInUseProtection, TaintNodesByCondition, ValidatingAdmissionPolicy, ValidatingAdmissionWebhook. The order of plugins in this flag does not matter.
```

`kube-apiserver` 파드 내에서 확인해봤습니다. 메세지 마지막에 모든 어드미션 컨트롤러의 목록이 나열되어 있습니다:
- AlwaysAdmit
- AlwaysDeny
- AlwaysPullImages
- CertificateApproval
- CertificateSigning
- CertificateSubjectRestriction
- DefaultIngressClass
- DefaultStorageClass
- DefaultTolerationSeconds
- DenyServiceExternalIPs
- EventRateLimit
- ExtendedResourceToleration
- ImagePolicyWebhook
- LimitPodHardAntiAffinityTopology
- LimitRanger
- MutatingAdmissionWebhook
- NamespaceAutoProvision
- NamespaceExists
- NamespaceLifecycle
- NodeRestriction
- OwnerReferencesPermissionEnforcement
- PersistentVolumeClaimResize
- PersistentVolumeLabel
- PodNodeSelector
- PodSecurity
- PodTolerationRestriction
- Priority
- ResourceQuota
- RuntimeClass
- SecurityContextDeny
- ServiceAccount
- StorageObjectInUseProtection
- TaintNodesByCondition
- ValidatingAdmissionPolicy
- ValidatingAdmissionWebhook

`NamespaceLifecycle`는 네임스페이스의 생성과 삭제를 제어합니다. 이 플러그인에 의해 `kube-public` 네임스페이스는 삭제할 수 없습니다.

```sh
$ k delete ns kube-public
Error from server (Forbidden): namespaces "kube-public" is forbidden: this namespace may not be deleted
```

하지만 플러그인을 비활성화하면 삭제할 수 있습니다.

```yaml
# $ vi /etc/kubernetes/manifests/kube-apiserver.yaml
apiVersion: v1
kind: Pod
metadata:
  ...
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    ...
    - --disable-admission-plugins=NamespaceLifecycle # 수정 후 저장
    - --enable-admission-plugins=NodeRestriction
    ...
# kube-apiserver와 다른 컴포넌트가 재시작 되는데 시작이 걸립니다.
# watch crictl ps 로 모니터
```

이제 `NamespaceLifecycle` 플러그인이 비활성화 되었기 때문에 `kube-public` 네임스페이스를 삭제할 수 있습니다.

```sh
$ k delete ns kube-public
namespace "kube-public" deleted
```
