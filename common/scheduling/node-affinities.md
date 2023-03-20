# Node Affinities

_노드 어피니티(affinities, 친화도)_는, 노드 셀렉터처럼, 스케쥴 될 노드에 대한 레이블 기반의 조건을 파드에 명세합니다.  또 테인트와 달리 스케쥴이 되길 바라는 노드의 레이블 조건을 명세합니다.

```yaml
# k run pod1 --image nginx $do 의 결과 기반
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - node-1
            - node-2
  containers:
  - image: nginx
    name: pod1
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

노드 어피니티는 파드 `.spec.affinity.nodeAffinity` 에 정의합니다.

첫번째 노드 어피니티 타입은 `requiredDuringSchedulingIgnoredDuringExecution` 입니다. 노드 셀렉터와 비슷하지만, 매치 표현식(`matchExpressions`)를 통해 좀 더 다양한 옵션이 있습니다. 표현식의 연산자는 `In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt` 그리고 `Lt`가 있습니다.

위 파드는 `kubernetes.io/hostname` 레이블 값이 `node-1` 또는 `node-2` 인 노드에만 스케쥴 됩니다.

두번째 노드 어피티니 타입은 `preferredDuringSchedulingIgnoredDuringExecution` 입니다.

```yaml
# k run pod2 --image nginx $do 의 결과 기반
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod2
  name: pod2
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 10
        preference:
          matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - node-4
  containers:
  - image: nginx
    name: pod2
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

`requiredDuringSchedulingIgnoredDuringExecution`와 달리, 레이블이 있는 노드에만 스케쥴 되도록 강제하지 않고, 선호사항(`preference`)을 명시하는 더 약한(soft) 규칙입니다. 가중치(`weight`)는 1\~100의 값이고, 해당 노드와 매치 표현식에 일치했을 때 더해지는 점수입니다.

따라서 우리 실습 환경엔 `kubernetes.io/hostname=node-4` 즉, `node-4`는 없지만 위 파드는 스케쥴 될 것입니다.

```bash
# 위 매니페스트 apply 후
$ k get po pod2 -owide
NAME   READY   STATUS    RESTARTS   AGE     IP            NODE     NOMINATED NODE   READINESS GATES
pod2   1/1     Running   0          5m30s   172.16.2.36   node-3   <none>           <none>

```

실습 환경을 정리합니다.

```bash
$ k delete po pod1 pod2
pod "pod2" deleted
pod "pod1" deleted
```

### 정리

* 노드 어피니티는, 노드 셀렉터와 비슷하지만, 더 많은 옵션으로 파드 스케쥴 조건을 명세한다.
  * `requiredDuringSchedulingIgnoredDuringExecution`은 레이블 매치 표현식으로 파드가 스케쥴 될 노드를 제한한다.
  * `preferredDuringSchedulingIgnoredDuringExecution`는 파드가 스케쥴 되길 선호하는 매치 표현식을 명세하기 때문에 매치하는 노드가 없더라도 스케쥴 될 수 있다.

### 실습

* 위 실습의 `pod1`이 `node-1`에도 스케쥴 되게 하려면 어떻게 해야할까?

### 참고

* [https://kubernetes.io/ko/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity](https://kubernetes.io/ko/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)
* [https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#NodeAffinity](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#NodeAffinity)
