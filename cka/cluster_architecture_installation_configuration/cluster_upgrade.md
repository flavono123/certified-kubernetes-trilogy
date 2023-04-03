# Cluster Upgrade

`kubeadm`을 사용해 클러스터의 쿠버네티스 버전을 업그레드 해보겠습니다. 그전에 워크로드 중단 없이, 성공적으로 업그레이드 하기 위해서 쿠버네티스 버전 정책을 알아보겠습니다.

## 쿠버네티스 버전 정책
쿠버네티스 버전은 semver(Semantic Version) `x.y.z` 형식으로 표현됩니다. 여기서 `x`는 메이저 버전, `y`는 마이너 버전, `z`는 패치 버전입니다.

쿠버네티스는 최근 3개의 마이너 버전을 지원합니다.
따라서 가장 최신 버전이 `1.26.x`라면 현재 최신 버전을 포함하여 `1.24.x`, `1.25.x` 버전을 지원합니다. 이는 쿠버네티스 버전이 `1.26.x`로 업그레이드 되더라도 `1.24.x`, `1.25.x` 버전의 클러스터를 관리할 수 있다는 의미입니다.

반대로 `1.23.x` 아래 버전의 클러스터는 더 이상 지원되지 않기 때문에 업그레이드를 해야 합니다.

### 버전 차이(skew) 정책
쿠버네티스 각 컴포넌트간 버전 차이는 1개 또는 2개의 마이너 버전까지 허용됩니다.
- kube-apiserver: `x.y.z`
- kube-controller-manager, kube-scheduler: `x.y.z`, `x.(y-1).z`
- kubelet: `x.y.z`, `x.(y-1).z`, `x.(y-2).z`
  - (\* kube-proxy는 kubelet과 동일한 버전을 사용해야 합니다.)
- kubectl: `x.y.z`, `x.(y-1).z`, `x.(y+1).z`

kube-apiserver를 기준으로, kube-controller-manager, kube-scheduler는 1개의 마이너 버전 하위호환성이 있습니다. kubelet은 2개의 마이너 버전 하위호환성이 있습니다. kubectl은 1개의 마이너 버전 상하위호환성이 있습니다.

kube-apiserver를 최신 버전인 `1.26.x`로 예를 든다면 구성 가능한 컴포넌트 버전은 다음과 같습니다.
- kube-apiserver: `1.26.x`
- kube-controller-manager, kube-scheduler: `1.26.x`, `1.25.x`
- kubelet: `1.26.x`, `1.25.x`, `1.24.x`
- kubectl: `1.26.x`, `1.25.x`, `1.27.x`


### 업그레이드 시 버전 차이
위 버전 차이 정책을 따라 업그레이드 시에는 kube-apiserver를 먼저 업그레이드 해야 합니다. 그 후 kube-controller-manager, kube-scheduler, kubelet을 업그레이드 해야 합니다. 마지막으로 kubectl을 업그레이드 해야 합니다. 그러면 업그레이드 동안 버전 차이 정책을 만족하게 되어 클러스터가 정상적으로 동작합니다.

kubeadm으로 업그레이드를 하게 되면 kube-apiserver를 포함해 kube-controller-manager, kube-scheduler의 코어 컴포넌트와 컨트롤플레인의 kubelet을 먼저 업그레이드 합니다. 그리고 워커노드의 kubelet을 하나씩 업그레이드 합니다.

## kubeadm 클러스터 업그레이드
kubeadm을 사용해 클러스터를 업그레이드 해보겠습니다. 먼저 현재 클러스터의 쿠버네티스 버전을 확인합니다.

### 클러스터 버전 확인
```sh
$ k version
WARNING: This version information is deprecated and will be replaced with the output from kubectl version --short.  Use --output=yaml|json to get the full version.
Client Version: version.Info{Major:"1", Minor:"26", GitVersion:"v1.26.1", GitCommit:"8f94681cd294aa8cfd3407b8191f6c70214973a4", GitTreeState:"clean", BuildDate:"2023-01-18T15:58:16Z", GoVersion:"go1.19.5", Compiler:"gc", Platform:"linux/amd64"}
Kustomize Version: v4.5.7
Server Version: version.Info{Major:"1", Minor:"26", GitVersion:"v1.26.1", GitCommit:"8f94681cd294aa8cfd3407b8191f6c70214973a4", GitTreeState:"clean", BuildDate:"2023-01-18T15:51:25Z", GoVersion:"go1.19.5", Compiler:"gc", Platform:"linux/amd64"}

# 또는
$ k version -oyaml | yq .serverVersion.gitVersion
v1.26.1
```

서버 버전을 확인하면 클러스터 버전은 `v1.26.1` 입니다. 최신 패치 버전을 확인하고 업그레이드 해보겠습니다.

```sh
$ apt update
$ apt-cache madison kubeadm | head -1
   kubeadm |  1.26.3-00 | https://apt.kubernetes.io kubernetes-xenial/main amd64 Packages

$ apt-cache madison kubelet | head -1
   kubelet |  1.26.3-00 | https://apt.kubernetes.io kubernetes-xenial/main amd64 Packages

$ apt-cache madison kubectl | head -1
   kubectl |  1.26.3-00 | https://apt.kubernetes.io kubernetes-xenial/main amd64 Packages
```

### 컨트롤플레인 업그레이드

업그레이드 할 목표 버전 `1.26.3`으로 kubeadm 패키지를 먼저 업그레이드 합니다.

```sh
$  apt-mark unhold kubeadm && \
 apt-get update && apt-get install -y kubeadm=1.26.3-00 && \
 apt-mark hold kubeadm
```

다운로드한 패키지가 `1.26.3`으로 업그레이드 되었는지 확인합니다.

```sh
$ kubeadm version -oyaml | yq .clientVersion.gitVersion
v1.26.3
```

업그레이드 계획(plan)을 확인합니다.

```sh
$ kubeadm upgrade plan
[upgrade/config] Making sure the configuration is correct:
...(생략)
Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT       TARGET
kubelet     3 x v1.26.1   v1.26.3

Upgrade to the latest version in the v1.26 series:

COMPONENT                 CURRENT   TARGET
kube-apiserver            v1.26.1   v1.26.3
kube-controller-manager   v1.26.1   v1.26.3
kube-scheduler            v1.26.1   v1.26.3
kube-proxy                v1.26.1   v1.26.3
CoreDNS                   v1.9.3    v1.9.3
etcd                      3.5.6-0   3.5.6-0

You can now apply the upgrade by executing the following command:

        kubeadm upgrade apply v1.26.3

_____________________________________________________________________
...(생략)
```

업그레이드 될 컴포넌트들의 버전을 확인합니다. `kubeadm upgrade apply`를 사용해 목표 버전으로 업그레이드 합니다.

```sh
$ kubeadm upgrade apply v1.26.3
...(생략)
[upgrade/version] You have chosen to change the cluster version to "v1.26.3"
[upgrade/versions] Cluster version: v1.26.1
[upgrade/versions] kubeadm version: v1.26.3
[upgrade] Are you sure you want to proceed? [y/N]: y
...(생략)
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.26.3". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```

업그레이드가 성공하면 위와 같은 메시지가 출력되어야 합니다. 클러스터와 컴포넌트들을 버전을 확인해봅니다.

```sh
# 클러스터
$ k version -oyaml | yq .serverVersion.gitVersion
v1.26.3

# 컴포넌트
$ k -n kube-system get po -l tier=control-plane -oyaml | yq .items[].spec.containers[0].image
registry.k8s.io/etcd:3.5.6-0
registry.k8s.io/kube-apiserver:v1.26.3 # kube-apiserver
registry.k8s.io/kube-controller-manager:v1.26.3 # kube-	controller-manager
registry.k8s.io/kube-scheduler:v1.26.3 # kube-scheduler
```

클러스터와 Etcd를 제외한 컴포넌트들은 `v1.26.3`으로 업그레이드 되었습니다. Etcd는 쿠버네티스 버전으로 관리하지 않고 독립적인 버전을 사용하기 때문에 별도로 업그레이드 해야 합니다.

아직 kubelet은 업그레이드 되지 않았습니다.

```sh
$ k get no node-1
NAME     STATUS   ROLES           AGE     VERSION
node-1   Ready    control-plane   2d16h   v1.26.1
```

kubelet 업그레이드 전에 컨트롤플레인 노드를 drain 합니다.

```sh
$ k drain node-1 --ignore-daemonsets
node/node-1 cordoned
Warning: ignoring DaemonSet-managed Pods: ...(생략)
...
node/node-1 drained
```

`kubectl drain` 명령은 먼저 대상 노드에 더 이상 파드를 스케줄링하지 않도록 cordon 합니다. 그리고 대상 노드에 있는 파드를 모두 drain 합니다. 이 때 대몬셋 파드는 무시하도록 `--ignore-daemonsets` 옵션을 사용합니다.

kubelet 패키지도 같은 목표 버전으로 다운로드 받습니다.

```sh
$ apt-mark unhold kubelet && \
 apt-get update && apt-get install -y kubelet=1.26.3-00 && \
 apt-mark hold kubelet
```

다운로드한 패키지가 `1.26.3`으로 업그레이드 되었는지 확인하고 kubelet을 재시작합니다.

```sh
# 확인
$ kubelet --version
Kubernetes v1.26.3

# 재시작
$ systemctl daemon-reload
$ systemctl restart kubelet
```

새로 시작된 kubelet 서비스가 `1.26.3`으로 업그레이드 되었는지 확인합니다. 서비스 상태와 로그도 확인해봅니다.

```sh
# node-1의 kubelet 버전 확인
$ k get no
NAME     STATUS     ROLES           AGE     VERSION
node-1   Ready      control-plane   2d16h   v1.26.3
node-2   NotReady   <none>          2d16h   v1.26.1
node-3   NotReady   <none>          2d16h   v1.26.1

# kubelet 서비스 상태 확인
$ systemctl status kubelet
...(생략)
# active (running) 상태 확인

# kubelet 로그 확인
$ journalctl -u kubelet -f
...(생략)
```

kubelet이 정상적으로 업그레이드 되었습니다. 컨트롤플레인이 다시 파드 스케쥴 가능하도록 `uncordon` 하고 워커 노드 업그레이드로 넘어갑니다.

```sh
$ k uncordon node-1
node/node-1 uncordoned

$ k get no
NAME     STATUS     ROLES           AGE     VERSION
node-1   Ready      control-plane   2d17h   v1.26.3
node-2   NotReady   <none>          2d16h   v1.26.1
node-3   NotReady   <none>          2d16h   v1.26.1
```


### 워커 노드 업그레이드

`node-2` 먼저 진행하겠습니다. 컨트롤플레인과 마찬가지로 kubeadm 패키지를 목표 버전 `1.26.3` 으로 다운로드 받습니다.

```sh
# gcloud compute ssh node-2; node-2에 접속
# sudo -i; 루트 로그인
$ apt-mark unhold kubeadm && \
 apt-get update && apt-get install -y kubeadm=1.26.3-00 && \
 apt-mark hold kubeadm

 # 확인
$ kubeadm version -oyaml | yq .clientVersion.gitVersion
v1.26.3
```

kubeadm 패키지가 `1.26.3`으로 업그레이드 되었습니다. `kubeadm upgrade node` 명령으로 kubelet 구성(config)을 업그레이드 합니다.

```sh
$ kubeadm upgrade node
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks
[preflight] Skipping prepull. Not a control plane node.
[upgrade] Skipping phase. Not a control plane node.
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml" # kubelet config 업그레이드
[upgrade] The configuration for this node was successfully updated!
[upgrade] Now you should go ahead and upgrade the kubelet package using your package manager.
```

kubelet 서비스 업그레이드 전에 워커 노드도 drain 합니다.

```sh
# node-1에서
$ k drain node-2 --ignore-daemonsets
...(생략)
node/node-2 drained

# STATUS 확인
$ k get no node-2
NAME     STATUS                     ROLES    AGE     VERSION
node-2   Ready,SchedulingDisabled   <none>   2d22h   v1.26.1
```

kubelet 패키지도 같은 목표 버전으로 다운로드 받습니다.

```sh
# node-2에서
$ apt-mark unhold kubelet && \
 apt-get update && apt-get install -y kubelet=1.26.3-00 && \
 apt-mark hold kubelet

# 패키지 버전 확인
$ kubelet --version
Kubernetes v1.26.3
```

kubelet을 재시작하고 상태 확인 후 uncordon 합니다.

```sh
$ systemctl daemon-reload
$ systemctl restart kubelet

# 상태 확인
$ systemctl status kubelet
...(생략)
# active (running) 상태 확인

# 로그 확인
$ journalctl -u kubelet -f
...(생략)



# (node-1에서 실행)
# uncordon
$ k uncordon node-2
node/node-2 uncordoned

# node-2의 kubelet 버전 확인
$ k get no
NAME     STATUS   ROLES           AGE     VERSION
node-1   Ready    control-plane   2d22h   v1.26.3
node-2   Ready    <none>          2d22h   v1.26.3
node-3   Ready    <none>          2d22h   v1.26.1

```

`node-3`도 동일하게 진행합니다.

---
### 참고
- [kubeadm 클러스터 업그레이드](https://kubernetes.io/ko/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [Semver](https://semver.org/lang/ko/)
- [버전 차이(skew) 정책](https://kubernetes.io/ko/releases/version-skew-policy/)
