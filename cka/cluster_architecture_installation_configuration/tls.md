# TLS

TLS 인증서는 클러스터 내부의 모든 통신을 암호화하는데 사용되고 외부 사용자의 인증을 위해 사용됩니다. TLS 인증서는 표준 이름인 X509, 또는 구조 이름인 PKI(Public Key Infrastructure)로 알려져 있습니다(이하 인증서로 통일). 인증서는 Kubernetes 클러스터 구성 요소 간의 통신을 암호화하고 서명하여 데이터 무결성을 보호합니다. 이러한 인증서는 Kubernetes API 서버, etcd, kubelet 및 Kubernetes 서비스와 같은 다양한 구성 요소에 대한 인증을 제공합니다. 또한 인증서 관리와 관련된 보안 사항을 준수하는 것이 중요합니다. 이를 위해 Kubernetes는 자동 인증서 갱신 및 로테이션을 지원하며, 인증서의 기밀성과 무결성을 보호하기 위해 암호화된 저장소에 인증서를 저장하는 것을 권장합니다.

## 컴포넌트 인증서 살펴보기
컨트롤플레인 노드 /etc/kubernetes/pki를 살펴보면 다음과 같은 인증서가 있습니다:
```sh
ls -1 /etc/kubernetes/pki/
apiserver-etcd-client.crt
apiserver-etcd-client.key
apiserver-kubelet-client.crt
apiserver-kubelet-client.key
apiserver.crt
apiserver.key
ca.crt
ca.key
etcd
front-proxy-ca.crt
front-proxy-ca.key
front-proxy-client.crt
front-proxy-client.key
sa.key
sa.pub
```

이 경로는 kubeadm으로 클러스터 설치 시 기본 값이고 `kubeadm init` 의 `--cert-dir` 옵션으로 변경할 수 있습니다:
```sh
$ kubeadm init --help | grep cert-dir
      --cert-dir string               The path where to save and store the certificates. (default "/etc/kubernetes/pki")
```

### CA 인증서
클러스터 CA(Certificate Authority)의 대칭키는 `ca.crt`, `ca.key` 입니다. 다음 명령으로 인증서(공개키, `*.crt`)를 확인할 수 있습니다:
```sh
$ openssl x509 -in /etc/kubernetes/pki/ca.crt -text -noout
...(생략)
```
- `x509`: 인증서 파싱하기 위한 명령([표준](https://ko.wikipedia.org/wiki/X.509) 이름)
- `-text`: 인증서 내용을 텍스트로 출력
- `-noout`: 인코딩된 인증서 내용을 출력하지 않음

발급자(issuer)와 주체(subject)를 확인하면 self-signed 인증서임을 알 수 있습니다:
```sh
$ openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -issuer -subject
issuer=CN = kubernetes
subject=CN = kubernetes
```

### API 서버 인증서(서버)
API 서버 인증서를 확인해봅니다:
```sh
$ openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
...(생략)
$ openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -issuer -subject
issuer=CN = kubernetes
subject=CN = kube-apiserver
```

### kube-scheduler 인증서(클라이언트)
kube-scheduler는 API 서버와 통신할 때 사용하는 인증서입니다. 따라서 API 서버의 CA 인증서를 사용하여 서명된 클라이언트 인증서입니다. scheduler 인증서는 별도 키 파일이 아닌 구성(config) 파일에 저장되어 있습니다:
```sh
cat /etc/kubernetes/scheduler.conf | yq '.users[0].user | keys'
- client-certificate-data
- client-key-data
```

위 구성 파일 경로는 kube-scheduler 파드 매니페스트에서 확인할 수 있습니다(옵션 플래그 `--authentication-kubeconfig`):
```sh
$ cat /etc/kubernetes/manifests/kube-scheduler.yaml | yq '.spec.containers[0].command'
- kube-scheduler
- --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
- --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
- --bind-address=127.0.0.1
- --kubeconfig=/etc/kubernetes/scheduler.conf
- --leader-elect=true
```

다시 인증서로 돌아와, kube-scheduler의 인증서는 구성 파일의 키 `client-certificate-data` 에 base64로 인코딩 되어 저장되어 있습니다:
```sh
$ cat /etc/kubernetes/scheduler.conf | yq '.users[0].user["client-certificate-data"]' | base64 -d | openssl x509 -text -noout
...(생략)

$ cat /etc/kubernetes/scheduler.conf | yq '.users[0].user["client-certificate-data"]' | base64 -d | openssl x509 -noout -issuer -subject
issuer=CN = kubernetes
subject=CN = system:kube-scheduler
```

주체 이름 `system:kube-scheduler` 는, 나중에 살펴 볼, 클러스터롤바인딩(`ClusterRoleBinding`)이며, API 서버의 RBAC(Role-Based Access Control) 정책에 의해 kube-scheduler가 API 서버에 접근할 수 있는 권한을 부여합니다.

<details>
<summary>Q1. 클러스터의 다른 CA 인증서를 찾아 보세요(참고 링크, "PKI 인증서 및 요구 사항", 활용)</summary>

```sh
# Etcd CA 인증서
$ ls -1 /etc/kubernetes/pki/etcd
ca.crt
ca.key
healthcheck-client.crt
healthcheck-client.key
peer.crt
peer.key
server.crt
server.key

$ openssl x509 -in /etc/kubernetes/pki/etcd/ca.crt -noout -issuer -subject
issuer=CN = etcd-ca
subject=CN = etcd-ca

# Basic Contraints 확장 값에서도 확인 가능
openssl x509 -in /etc/kubernetes/pki/etcd/ca.crt -noout -text | grep -i "basic constraints" -A 1
            X509v3 Basic Constraints: critical
                CA:TRUE

# Front Proxy CA 인증서
$ ls -1 /etc/kubernetes/pki/front-proxy-ca.*
/etc/kubernetes/pki/front-proxy-ca.crt
/etc/kubernetes/pki/front-proxy-ca.key

$ openssl x509 -in /etc/kubernetes/pki/front-proxy-ca.crt -noout -issuer -subject
issuer=CN = front-proxy-ca
subject=CN = front-proxy-ca
```

</details>

<details>
<summary>Q2. kube-scheduler 외에 다른 컴포넌트 인증서를 찾아보세요(참고 링크, "PKI 인증서 및 요구 사항", 활용)</summary>

```sh
# kube-controller-manager 의 kubeconfig 파일
$ cat /etc/kubernetes/manifests/kube-controller-manager.yaml | yq '.spec.containers[0].command' | grep authentication-kubeconfig
- --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf

# kube-controller-manager 의 인증서
$ cat /etc/kubernetes/controller-manager.conf | yq '.users[0].user["client-certificate-data"]' | base64 -d | openssl x509 -noout -text
...(생략)

$ cat /etc/kubernetes/controller-manager.conf | yq '.users[0].user["client-certificate-data"]' | base64 -d | openssl x509 -noout -issuer -subject
issuer=CN = kubernetes
subject=CN = system:kube-controller-manager
```

</details>

---

### 참고
- [PKI 인증서 및 요구 사항](https://kubernetes.io/ko/docs/setup/best-practices/certificates/)
- [kubeadm을 사용한 인증서 관리](https://kubernetes.io/ko/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
- [X.509](https://ko.wikipedia.org/wiki/X.509)
