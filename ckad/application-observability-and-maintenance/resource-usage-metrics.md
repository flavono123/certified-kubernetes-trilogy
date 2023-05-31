# Metrics-server

`metrics-server`는 쿠버네티스 클러스터 내에서 워크로드의 리소스 사용량을 수집하는 컴포넌트입니다. 각 노드의 `kubelet`으로부터 CPU와 메모리 사용량을 수집합니다. 노드와 파드에 대해서 두 리소스 메트릭을 수집하며, 특히 파드의 것은 `kubelet`에 내장된 `cAdvisor`를 통해 수집합니다. 수집한 메트릭은 `kubectl top` 명령으로 확인할 수 있습니다(실습/시험 환경엔 `metrics-server`가 설치되어 있기 때문에 바로 요청해볼 수 있습니다).

```sh
$ k top no
NAME     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
node-1   256m         12%    1598Mi          41%
node-2   65m          3%     984Mi           25%
node-3   73m          3%     1172Mi          30%

$ k top po -n kube-system
NAME                             CPU(cores)   MEMORY(bytes)
coredns-787d4945fb-75ptx         2m           13Mi
coredns-787d4945fb-mpnxr         2m           16Mi
etcd-node-1                      31m          66Mi
kube-apiserver-node-1            52m          459Mi
kube-controller-manager-node-1   19m          66Mi
kube-proxy-jjmlb                 1m           19Mi
kube-proxy-tht2l                 1m           26Mi
kube-proxy-tkh4j                 1m           17Mi
kube-scheduler-node-1            3m           26Mi
metrics-server-f5c6df5db-bqx52   5m           32Mi
```


<details>
<summary>

Q1. 모든 네임스페이스의 파드 CPU/메모리 메트릭을 메모리 사용량이 많은 순서로 출력하세요.
</summary>

```sh
$ k top po -A --sort-by memory
```

</details>

```sh
