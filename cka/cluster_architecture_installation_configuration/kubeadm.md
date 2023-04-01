# Kubeadm

[Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
문서를 바탕으로 `kubeadm`을 사용한 쿠버네티스 클러스터 설치 과정을 알아보겠습니다. CKA 시험 환경은 `kubeadm`으로 설치되었고 우리 실습환경도 마찬가지입니다. **하지만 직접 `kubeadm`으로 클러스터를 설치하진 않을겁니다.**

### kube* 패키지 설치
먼저 Ubuntu 노드에 각각 `kubeadm`, `kubelet`, `kubectl`을 설치합니다.

```sh
## !NOTE: 따라 실행하지 않아도 됩니다
# apt 패키지 색인을 업데이트, 쿠버네티스 apt 리포지터리를 사용하는 데 필요한 패키지를 설치
$ sudo apt-get update && sudo apt-get install -y apt-transport-https curl
# 구글 클라우드의 공개 사이닝 키를 다운로드
$ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
# 쿠버네티스 apt 리포지터리를 추가
$ echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
# kubelet, kubeadm, kubectl을 설치하고 해당 버전을 고정
$ sudo apt-get update
$ sudo apt-get install -y kubelet kubeadm kubectl
$ sudo apt-mark hold kubelet kubeadm kubectl
```
### 컨트롤플레인 노드 초기화
컨트롤플레인 노드(`node-1`)에서 `kubeadm init` 명령을 실행합니다.

```sh
## !NOTE: 따라 실행하지 않아도 됩니다
$ sudo kubeadm init --pod-network-cidr 172.16.0.0/16
```
- `--pod-network-cidr`: 파드 IP를 할당할 CIDR 블록을 지정합니다.

설치가 끝나면 워커 노드가 클러스터에 조인(`join`) 할 수 있게 토큰을 생성합니다.
```sh
## !NOTE: 따라 실행하지 않아도 됩니다
$ kubeadm token create --print-join-command
# kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

- `--print-join-command`: 워커 노드에서 사용할 수 있는 `kubeadm join` 명령을 출력합니다.

파드 네트워크 구성이 잘 될 수 있도록 CNI 플러그인을 설치합니다. 우리 실습 환경에선 `calico`를 사용했습니다.

### 워커 노드 조인
워커 노드(`node-2`, `node-3`)에서 `kubeadm join` 명령을 실행합니다. 컨트롤플레인에서 토큰 생성 시 출력된 명령을 그대로 사용하면 됩니다.

```sh
## !NOTE: 따라 실행하지 않아도 됩니다
$ sudo kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

### 클러스터 상태 확인
클러스터가 정상적으로 구성되었는지 확인합니다. 노드를 조회해 모든 노드가 Ready 상태인지 확인합니다.

```sh
$ k get nodes
```

<details>
<summary>Q1. 설치된 <code>kubelet</code>, <code>kubeadm</code>, <code>kubectl</code> 패키지 버전을 확인하세요.</summary>

```sh
$ dpkg -l kubelet kubeadm kubectl
```

```sh
# 패키지가 아닌 각 바이너리, 프로세스 버전 확인 명령
$ kubelet --version
# 또는 k get nodes 결과 VERSION에서도 확인 가능
$ kubeadm version
$ kubectl version
```

</details>

<details>
<summary>Q2. <code>kubeadm</code>으로 설치 시 워커 노드 조인에 사용한 토큰을 확인해보세요.</summary>

```sh
$ kubeadm token list
```

</details>


---

### 참고
- [kubeadm 설치하기](https://kubernetes.io/ko/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
