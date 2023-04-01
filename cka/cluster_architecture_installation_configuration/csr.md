# Certificate Signing Requests

CSR(Certificate Signing Request)는 쿠버네티스에서 인증서를 발급하기 위해 필요한 정보를 담고 있는 요청서입니다. CSR은 클러스터에서 생성된 새로운 인증서를 요청하거나, 기존 인증서를 갱신하고자 할 때 사용됩니다.

CSR은 쿠버네티스 클러스터의 API 서버에 제출됩니다. CSR을 제출하면 API 서버는 요청서를 검증하고, 인증서 서명 요청을 반환합니다. 이후 인증서 서명 요청을 사용하여 신규 인증서를 발급하거나, 인증서 갱신을 진행합니다.

쿠버네티스 CSR API를 사용하는 방법이 있습니다. CSR 생성 후 적절한 권한이 있는 사용자는 API를 통해 CSR을 제출하고, 반환된 인증서를 클러스터 내에서 사용할 수 있습니다.

이제 클러스터 외부의 새로운 쿠버네티스 사용자의 인증서를 발급하는 방법을 알아보겠습니다.

## CSR 생성
개인키를 생성하고 CSR 파일 생성합니다.

```bash
$ openssl genrsa -out flavono123.key 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
..........................+++++
.....................................................+++++
e is 65537 (0x010001)

$ openssl req -new -key flavono123.key -out flavono123.csr -subj "/CN=flavono123"

$ ls -1 flavono123.*
flavono123.csr
flavono123.key
```

만든 CSR 파일을 base64로 인코딩하여 쿠버네티스 CSR 객체를 만듭니다.

```sh
$ cat flavono123.csr | base64 -w 0 # 확인
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRV...(생략)

$ cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: flavono123
spec:
  request: $(cat flavono123.csr | base64 -w 0)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF
certificatesigningrequest.certificates.k8s.io/flavono123 created
```

## CSR 승인
CSR을 생성하면 `Pending` 상태로 생성됩니다.

```sh
$ k get csr flavono123
NAME         AGE   SIGNERNAME                            REQUESTOR          REQUESTEDDURATION   CONDITION
flavono123   62s   kubernetes.io/kube-apiserver-client   kubernetes-admin   24h                 Pending
```

이제 CSR을 승인합니다.

```sh
$ k certificate approve flavono123
certificatesigningrequest.certificates.k8s.io/flavono123 approved

$ k get csr flavono123
NAME         AGE     SIGNERNAME                            REQUESTOR          REQUESTEDDURATION   CONDITION
flavono123   2m23s   kubernetes.io/kube-apiserver-client   kubernetes-admin   24h                 Approved,Issued
```

승인한 CSR 객체에서 인증서를 추출합니다.

```sh
$ k get csr flavono123 -o jsonpath='{.status.certificate}' | base64 -d > flavono123.crt
```

## 인증서 사용
Raw API로 인증서를 사용해보겠습니다. 먼저 인증서 없이 클러스터 API 서버에 접근하면 인증 오류가 발생합니다.

```sh
$ curl https://kubernetes:6443/healthz --resolve 'kubernetes:6443:127.0.0.1'
curl: (60) SSL certificate problem: unable to get local issuer certificate
...
```
- `--resolve` : DNS 이름을 IP 주소로 매핑합니다. 클러스터 인증서의 SAN(Subject Alternative Name)인 `kubernetes`로 접근하기 위해 필요합니다.

바로 위에서 생성한 인증서를 사용하여 클러스터 API 서버에 접근합니다.

```sh
$ curl https://kubernetes:6443/healthz --resolve 'kubernetes:6443:127.0.0.1' \
  --cacert /etc/kubernetes/pki/ca.crt \
  --cert flavono123.crt \
  --key flavono123.key
ok
```

<details>
<summary>Q1. <code>myuser.key</code>를 만들고 CSR 파일을 만들어 보세요.</summary>

```sh
$ openssl genrsa -out myuser.key 2048
$ openssl req -new -key myuser.key -out myuser.csr -subj "/CN=myuser"
```
</details>

<details>
<summary>Q2. <code>myuser</code> CSR을 생성하고 승인해 보세요.</summary>

```sh
# CSR 생성
$ cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: myuser
spec:
  request: $(cat myuser.csr | base64 -w 0)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF

$ k get csr myuser # 확인

# CSR 승인
$ k certificate approve myuser

$ k get csr myuser # 승인 상태 확인
```

</details>

<details>
<summary>Q3. <code>myuser</code> 인증서를 추출해 발급자, 주체를 확인해 보세요.</summary>

```sh
$ k get csr myuser -o jsonpath='{.status.certificate}' | base64 -d > myuser.crt

$ openssl x509 -in myuser.crt -noout -issuer -subject
```

</details>

---

### 참고
- [Certificate Signing Requests](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/)
