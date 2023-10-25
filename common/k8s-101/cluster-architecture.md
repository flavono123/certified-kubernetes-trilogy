# Cluster Architecture

## 컨트롤 플레인과 노드
컴퓨트 인스턴스이자 VM인 `node-1`, `node-2`, `node-3`은 모두 쿠버네티스 노드입니다. `node-1`은 컨트롤플레인노드이기도 합니다. 노드는 쿠버네티스 최소 워크로드 단위이자, 컨테이너를 실행하는, 파드가 실행되는 곳입니다. 즉 파드는 노드 위에서 실행됩니다. 컨트롤플레인엔 쿠버네티스 동작에 필요한 컴포넌트들이 실행됩니다.

## 코어 컴포넌트
쿠버네티스 클러스터를 구성하는 코어 컴포넌트는 다음과 같습니다.
`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `etcd`, `kubelet`, `kube-proxy`

## 파드 스케쥴
