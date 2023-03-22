# DaemonSet

> 📘 Cluster: **k8s**(default)
<br> `vagrant provision` 또는
<br> `vagrant destroy -f && vagrant up`

데몬셋(`DaemonSet`)은 클러스터 내 모든 노드에서 특정 파드가 실행되도록 보장하는 워크로드 객체입니다. 시스템 데몬, 로깅 에이전트 및 클러스터 내 모든 노드에서 실행해야 하는 유형의 작업에 자주 사용됩니다.

데몬셋은 디플로이먼트(`Deployment`)처럼, 노드 선택자(node selector), 어피니티(affinities) 및 톨러레이션(toleartion)을 포함하여 파드의 스케줄링과 배포를 제어하기 위한 여러 구성 옵션을 제공하고, 롤링 업데이트를 지원하여 새로운 파드로 오래된 파드를 교체할 때 다운타임 없이 수행할 수 있습니다. 