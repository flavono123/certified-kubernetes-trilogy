# Static Pods

> 📘 Cluster: **k8s**(default)
<br> `vagrant provision` 또는
<br> `vagrant destroy -f && vagrant up`

정적 파드(Static Pod)는 쿠버네티스에서 파드를 직접 노드에 배치하는 방법 중 하나입니다. 정적 파드는 kubelet이 감시하는 디렉토리(`staticPodPath`)에 포함된 YAML 파일을 사용하여 정의됩니다. 이러한 파일은 파드의 스펙을 정의하며, kubelet은 이 파일을 사용하여 파드를 노드에서 실행합니다. 정적 파드를 사용하면 Kubernetes API 서버가 아닌 노드에서 파드를 실행할 수 있으므로 수동으로 관리해야 합니다.