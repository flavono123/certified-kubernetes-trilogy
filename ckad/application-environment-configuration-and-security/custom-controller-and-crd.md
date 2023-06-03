# Custom Controller and CRD

## Custom Controller
쿠버네티스의 리소스는 리소스의 컨트롤러에 의해 관리됩니다. 예를 들어 ReplicaSet은 `spec.replicas`에 Pod의 수를 유지해야 합니다. ReplicaSet 리소스 매니페스트에 이를 정의하면 ReplicaSet 컨트롤러가 이를 관리합니다. ReplicaSet을 포함한 여러 기본 리소스들에 대한 컨트롤러는 쿠버네티스 코어 컴포넌트, `kube-controller-manager`에 내장되어 있습니다.

https://github.com/kubernetes/kubernetes/tree/039ae1edf5a71f48ced7c0258e13d769109933a0/pkg/controller

위 링크에서 컨트롤러들을 확인할 수 있습니다. 컨트롤러는 go 언어로 작성되어 있습니다. 이러한 컨트롤러들은 쿠버네티스의 기본 리소스들을 관리합니다.

쿠버네티스는 기본 리소스 뿐만 아니라 사용자 정의 리소스를 정의하고 관리할 수 있도록 확장하는 기능이 있습니다. 이 때 필요한 컨트롤러가 커스텀 컨트롤러입니다. 커스텀 컨트롤러는 쿠버네티스 코어 컴포넌트에 내장되어 있지 않기 때문에 직접 구현해야 합니다. 하지만 커스텀 컨트롤러를 구현하는 것은 CKAD 시험 범위 밖이기 때문에 여기서는 다루지 않습니다. 대신 커스텀 컨트롤러가 제어하는 커스텀 리소스를 만들어 보겠습니다.

## Custom Resource
커스텀 리소스는 쿠버네티스의 기본 리소스가 아닌 사용자 정의 리소스입니다. 이미 알고 있는 다른 쿠버네티스 리소스와 비슷한 매니페스트로 작성할 수 있습니다.

```yaml
apiVersion: ckt.example.com/v1
kind: Support
metadata:
  name: example
  labels:
    app: example
spec:
  title: refund
  content: defects
  email: flavono123@gmail.com
```

고객 서비스 팀에서 고객 문의 처리에 사용할 수 있는 티켓 리소스, `Support`를 만들어 봤습니다. 스펙엔 문의에 대한 제목(`spec.title`), 내용(`spec.content`) 그리고 문의한 고객의 이메일(`spec.email`) 필드가 있습니다. 쿠버네티스 커스텀 리소스는 이렇게 일반적인 내용으로 자유로운 확장이 가능합니다.

하지만 위 객체를 생성하려면 오류가 발생합니다.

```sh
error: resource mapping not found for name: "example" namespace: "" from "STDIN": no matches for kind "Support" in version "ckt.example.com/v1"
ensure CRDs are installed first
```

커스텀 리소스를 만들기 위해선 먼저 그것을 정의하는 커스텀 리소스 데피니션(Custom Resource Definition, CRD)을 만들어야 합니다.

## Custom Resource Definition
`Support` 커스텀 리소스에 대한 CRD는 다음처럼 만들 수 있습니다:
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: supports.ckt.example.com
spec:
  group: ckt.example.com
  scope: Namespaced
  names:
    plural: supports
    singular: support
    kind: Support
    shortNames:
      - sp
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                title:
                  type: string
                content:
                  type: string
                email:
                  type: string
```

apiVersion은 `apiextensions.k8s.io/v1`이며, kind는 `CustomResourceDefinition`입니다.

metadata.name은, 이어서 설명하는, plural 이름과 group을 합쳐서 만듭니다.

스펙을 살펴보면, group은 기존 리소스 그리고 다른 커스텀 리소스 그룹과 구분할 수 있는 임의의 DNS 이름 규칙의 이름을 줄 수 있습니다.

scope는 리소스의 범위를 지정합니다. `Namespaced`는 네임스페이스 내에서만 사용할 수 있고, `Cluster`는 클러스터 전체에서 사용할 수 있습니다.

names는 리소스의 이름을 지정합니다. plural은 복수형 이름, singular은 단수형 이름, kind는 리소스의 종류를 지정합니다. shortNames는 짧은 이름을 지정합니다. 이는 `kubectl` 명령어에서 `pods` 대신 `po`, `nodes` 대신 `no` 등으로 사용하는 방법과 같게 쓸 수 있습니다.

versions는 리소스의 버전을 지정합니다. v1은 served와 storage가 true로 설정되어 있습니다. served는 이 리소스가 API 서버에 의해 제공되는지 여부를 지정합니다. storage는 이 리소스가 etcd에 저장되는지 여부를 지정합니다. 이 두 값은 일반적으로 같게 설정합니다.

schema는 리소스의 스펙을 지정합니다. 이는 openAPIV3Schema로 지정합니다. 이는 리소스의 스펙을 JSON 스키마로 지정합니다. `Support`에서 정의하려는, `spec.title`, `spec.content`, `spec.email` 필드를 모두 string 타입으로 정의했습니다.

CRD를 생성하면 커스텀 리소스를 생성할 수 있고, `kubectl`을 통해 확인할 수도 있습니다:

```sh
# k get customresourcedefinitions.apiextensions.k8s.io supports.ckt.example.com
$ k get crd supports.ckt.example.com
NAME                       CREATED AT
supports.ckt.example.com   2023-06-03T03:47:06Z

$ k create -f support.yaml
support.ckt.example.com/example created

$ k get sp
NAME      AGE
example   24s

$ k get sp example -oyaml
apiVersion: ckt.example.com/v1
kind: Support
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"ckt.example.com/v1","kind":"Support","metadata":{"annotations":{},"labels":{"app":"example"},"name":"example","namespace":"default"},"spec":{"content":"defects","email":"flavono123@gmail.com","title":"refund"}}
  creationTimestamp: "2023-06-03T03:48:18Z"
  generation: 1
  labels:
    app: example
  name: example
  namespace: default
  resourceVersion: "840221"
  uid: 3a9c3192-4537-4b4d-977e-5127c8fb12b7
spec:
  content: defects
  email: flavono123@gmail.com
  title: refund
```

CRD를 정의한 후에 커스텀 리소스를 만들었습니다. 하지만 커스텀 컨트롤러가 없기 때문에 리소스가 생성되어도 아무 일도 일어나지 않습니다. 커스텀 컨트롤러까지 만들어 커스텀 리소스를 제어하면 완전히 쿠버네티스 API를 확장하게 됩니다.
