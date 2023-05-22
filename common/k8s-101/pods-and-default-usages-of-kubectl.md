# 파드와 `kubectl`의 기본 사용법

노드 `node-1`에 접속하고 루트로 로그인합니다:

```shell
$ gcloud compute ssh node-1
username@node-1:~$ sudo -i
root@node-1:~#
```

기본적으로 실습은 `node-1` 노드에서 진행합니다. 따라서 이후에 쉘 프롬프트를 `$`만 표시하였다면, `node-1`에 루트로 로그인 했음을 의미합니다. 이 환경에선 `kubectl` 명령을 사용할 수 있도록 구성돼있습니다:

## 파드

파드는 쿠버네티스에서 배포할 수 있는 가장 작은 컴퓨팅 단위입니다. 파드는 하나 이상의 컨테이너를 가질 수 있습니다.

`kubectl get pods` 명령으로 파드를 확인할 수 있습니다:


```shell
$ kubectl get pods
No resources found in default namespace.
```

파드가 없는 것을 확인할 수 있습니다. 클러스터 내 모든 파드를 확인하려면 `--all-namespaces` 옵션을 사용합니다:

```shell
No pod in the cluster. List pods from the all Namespaces:

```shell
$ kubectl get pods --all-namespaces
NAMESPACE        NAME                                        READY   STATUS    RESTARTS      AGE
ingress-nginx    ingress-nginx-controller-8574b6d7c9-ldp64   1/1     Running   0             5d18h
kube-flannel     kube-flannel-ds-d2rq2                       1/1     Running   0             5d18h
kube-flannel     kube-flannel-ds-lnmvs                       1/1     Running   0             5d18h
kube-flannel     kube-flannel-ds-trj4r                       1/1     Running   0             5d18h
kube-system      coredns-565d847f94-5p5p5                    1/1     Running   0             5d18h
kube-system      coredns-565d847f94-fqbmw                    1/1     Running   0             5d18h
kube-system      etcd-node-1                                 1/1     Running   0             5d18h
kube-system      kube-apiserver-node-1                       1/1     Running   0             5d18h
kube-system      kube-controller-manager-node-1              1/1     Running   1 (10h ago)   5d18h
kube-system      kube-proxy-9ln5m                            1/1     Running   0             5d18h
kube-system      kube-proxy-j4chz                            1/1     Running   0             5d18h
kube-system      kube-proxy-vkf87                            1/1     Running   0             5d18h
kube-system      kube-scheduler-node-1                       1/1     Running   1 (10h ago)   5d18h
metallb-system   metallb-controller-99b88c55f-8csg7          1/1     Running   0             5d18h
metallb-system   metallb-speaker-9p278                       1/1     Running   0             5d18h
metallb-system   metallb-speaker-l7chx                       1/1     Running   0             5d18h
metallb-system   metallb-speaker-qjngz                       1/1     Running   0             5d18h

```

`kube-system` 네임스페이스에 있는 파드들을 확인할 수 있습니다. 이 파드들은 쿠버네티스의 핵심 컴포넌트들입니다. 이후에 자세히 다루겠습니다.

## 자동 완성과 축약어

CK\* 시험에서 중요한 것 중 하나는 시간 관리입니다. 타이핑을 줄이면 시험 시간을 절약할 수 있습니다.

`kubectl` 대신 alias **`k`**를 사용할 수 있습니다:

```shell
$ k get pods --all-namespaces
```

그리고 서브커맨드, 옵션, 인자에 대한 자동 완성을 사용할 수 있습니다. 명령이나 인자 일부를 타이핑하고 탭키를 눌러 완성시킬 수 있습니다:

```shell
$ k g<tab>(get) po<tab>(pod) --all-n<tab>(--all-namespace)
```

실제 시험 환경에서도, 실습 환경처럼, alias `k` 와 자동 완성을 사용할 수 있습니다.

축약어도 사용할 수 있습니다. 예를 들어, `po`는 `pod(s)`의 축약어입니다. `--all-namespace`도 `-A`와 같습니다:
```shell
$ k get po -A
```

앞으로 다른 쿠버네티스 객체나 개념을 배우면서도 이런 축약어들을 알려드리겠습니다.

### 첫 파드 실행하기

이제 첫 파드를 실행해보겠습니다. `run` 서브커맨드는 파드를 실행합니다:

```shell
$ k run test --image=nginx
pod/test created
$ k get po
NAME   READY   STATUS    RESTARTS   AGE
test   1/1     Running   0          19s
```

`test` 파드가 생성됐습니다. `run` 서브커맨드에서, 컨테이너 이미지 태그에 해당하는, `--image` 옵션은 필수입니다.

## `describe`

파드에 대한 더 자세한 정보를 확인하려면 **`describe`** 서브커맨드를 사용합니다:

```shell
$ k describe po test
```

`describe`의 출력은 `get`보다 더 자세한 내용을 담고 있습니다. 파드의 상태, 이벤트, 컨테이너의 상태 등을 확인할 수 있습니다.

파드 뿐만 아니라 다른 리소스들에 대해서도 `describe` 서브커맨드로 확인할 수 있습니다. 특히 문제가 생겼을 때, `describe` 서브커맨드로 확인하는 것이 유용합니다.

## 명령형(Imperative) vs. 선언형(Declarative)

앞서 `run` 서브커맨드로 파드를 생성한 방법은 **명령형** 방법입니다. 이와 달리 **선언형**으로 파드를 실행할 수도 있습니다.

먼저, 파드의 선언(YAML)을 확인해보겠습니다. `-o(--output)` 옵션은 출력 포맷을 지정합니다:

```shell
$ k get po test -oyaml
apiVersion: v1
kind: Pod
metadata:
...
spec:
  containers:
  - image: nginx
  ...
status:
  ...
```

YAML 출력에서 파드의 컨테이너 이미지는, `run`의 `--image` 옵션 인자로 준, `nginx` 임을 확인할 수 있습니다(`.spec.contrainers[0].image`). 파드는 `spec`과 `status`를 가지고 있습니다. `spec`은 파드의 원하는 상태(desired state)를, `status`는 파드의 현재 상태(current state)를 나타냅니다.

선언형 방법으로 파드를 생성하는 것은 원하는 상태인 `spec`을 써두고 `apply` 서브커맨드로 적용하는것 입니다.:

이제 이 선언을 사용해 파드를 선언적으로 실행해보겠습니다. 이를 위해선 `apply` 서브커맨드를 사용합니다.

하지만 긴 YAML 파일을 모두 직접 외우고 타이핑할 필요는 없습니다. `kubectl` 엔 이를 위한 템플릿 만드는 방법을 제공합니다.

## "선언형"으로 두번째 파드 생성하기

```shell
$ k run test2 --image=nginx --dry-run=client -oyaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: test2
  name: test2
spec:
  containers:
  - image: nginx
    name: test2
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

`--dry-run=client` 옵션과 `-oyaml` 을 사용하면, 실제로 파드를 생성하지 않고, 파드의 선언(YAML)만 출력합니다. 이를 통해 선언을 확인하고, `apply` 서브커맨드로 적용할 수 있습니다:

```shell
$ k run test2 --image=nginx --dry-run=client -oyaml > pod.yaml
$ k apply -f pod.yaml
pod/test2 created
$ k get pod test2
NAME    READY   STATUS    RESTARTS   AGE
test2   1/1     Running   0          11s
```

`apply` 서브커맨드는 `-f(--filename)` 옵션으로 선언 파일을 받습니다.

**두가지 방법을 모두 익히고, 시험에서는 시간을 최대한 줄이는 방법을 쓰세요.** 어떤 명령의 모든 인자, 옵션 플래그 등을 외우고 있고 그걸로 문제 요구사항을 충족할 수 있다면 명령형 방법을 빠를 수 있습니다. 그게 아니라면 또는 한번 푼 문제를 검토하고 수정하려면 선언형 방법으로, YAML 파일을 남겨두고 수정하는 것이 더 빠를 수 있습니다.

다음 실습을 위해 `delete` 명령으로 생성한 파드를 삭제합니다.

```shell
$ k delete po test test2
pod "test" deleted
pod "test2" deleted
$ k get po
No resources found in default namespace.
```
