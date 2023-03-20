# Taints and Tolerations

### 테인트

_테인트(Taints)_는 특정 노드에 파드 집합이 스케쥴링 되는 것을 막는 기법입니다. 서브 명령 taint로 노드에 테인트를 추가합니다.

```bash
$ k taint no node-2 color=red:NoSchedule
node/node-2 tainted
$ k get no node-2 -oyaml | yq .spec.taints
- effect: NoSchedule
  key: color
  value: red
```

명령 문법은 `kubectl taint node <node> <key>=<val>:<effect> ...` 입니다. 키-값 쌍으로 정의하고 효과(effetct)는 다음 셋 중 하나입니다.

* `NoSchedule` : 톨러레이션이 없는 파드를 스케쥴하지 않음. 이미 실행 중인 톨러레이션이 없는 파드를 축출(evict)하지 않음.
* `PreferNoSchedule` :  톨러레이션이 없는 파드를 스케쥴하지 않으려 시도하지만 강제하진 않음. 이미 실행 중인 톨러레이션이 없는 파드를 축출하지 않음.
* `NoExecute` :톨러레이션이 없는 파드를 스케쥴하지 않음. 이미 실행 중인 톨러레이션이 없는 파드를 축출함.

또는 특정 키에 대해서만 테인트를 추가할 수도 있습니다.

```bash
$ k taint no node-3 color:NoExecute
node/node-3 tainted
$ k get no node-3 -oyaml | yq .spec.taints
- effect: NoExecute
  key: color
```

이제 파드를 실행을 요청하면, 모든 노드에 테인트가 있기 때문에, 스케쥴 되지 않습니다.

```bash
$ k run green --image nginx
pod/green created
$ k run red --image nginx
pod/red created
$ k get po
NAME    READY   STATUS    RESTARTS   AGE
green   0/1     Pending   0          7s
red     0/1     Pending   0          2s
$ k describe po green | tail -4
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  44s   default-scheduler  0/3 nodes are available: 1 node(s) had untolerated taint {color: red}, 1 node(s) had untolerated taint {color: }, 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
$ k describe po red | tail -4
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  47s   default-scheduler  0/3 nodes are available: 1 node(s) had untolerated taint {color: red}, 1 node(s) had untolerated taint {color: }, 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.

```

### 톨러레이션

테인트가 있는 노드에 파드가 스케쥴 될 수 있도록, 파드에 _톨러레이션(tolerations)_을 추가할 수 있습니다.

레이블 선택 연산자와 비슷하게, 톨러레이션도 키 존재 여부를 확인하는 연산자 `Exists` 가 있습니다. 다음 톨러레이션을 `green` 파드 `.spec.tolerations` 에 추가합니다(이미 두개의 톨러레이션이 있습니다).

```yaml
- effect: NoExecute
  key: color
  operator: Exists
```

```bash
$ k edit po green
pod/green edited
$ k get po green -w -owide
NAME    READY   STATUS    RESTARTS   AGE     IP            NODE     NOMINATED NODE   READINESS GATES
green   1/1     Running   0          5m47s   172.16.2.33   node-3   <none>           <none>

```

시간이 조금 지나면 톨러레이션 효과가 있는 `node-3`에 `green` 파드가 스케쥴 됩니다. `node-2`에 스케쥴 되게 하려면 파드는 키-값이 일치하는 톨러레이션이 필요합니다.

```yaml
  - effect: NoSchedule
    key: color
    value: red
    operator: Equal
```

```bash
$ k edit po red
pod/red edited
$ k get po red -owide -w
NAME   READY   STATUS    RESTARTS   AGE   IP            NODE     NOMINATED NODE   READINESS GATES
red    1/1     Running   0          11m   172.16.1.31   node-2   <none>           <none>
```

노드에 테인트를 제거하려면 제거하려는 테인트(`<key>=<val>:<effect>`) 뒤에 `-`(마이너스)를 붙여줍니다.

```bash
$ k taint no node-3 color:NoExecute-
node/node-3 untainted
$ k taint no node-2 color=red:NoSchedule-
node/node-2 untainted
$ k get no node-3 -oyaml | yq .spec.taints
null
$ k get no node-2 -oyaml | yq .spec.taints
null
```

실습 환경을 정리합니다.

```bash
$ k delete po red green
pod "red" deleted
pod "green" deleted

```

### 정리

* 톨러레이션이 없는, 특정 파드 집합이 스케쥴 되지 않도록 노드에 테인트를 추가할 수 있다.
* 테인트가 있는 노드에 스케쥴 될 수 있도록 파드에 톨러레이션을 추가할 수 있다.

### 실습

* 파드에 기본으로 설정된 다음 두 톨러레이션은 어떤 의미일까?

```yaml
- effect: NoExecute
  key: node.kubernetes.io/not-ready
  operator: Exists
  tolerationSeconds: 300
- effect: NoExecute
  key: node.kubernetes.io/unreachable
  operator: Exists
  tolerationSeconds: 300
```

* 위 실습에서 `node-2`, `node-3`에만 테인트를 추가했다. 왜 `node-1`에 파드가 스케쥴 되지 않았을까?
* 톨러레이션의 키-값과 연산자는 유효하지만 `effect` 가 다르면 어떻게 될까?
  * 테인트 `NoSchedule` - 톨러레이션 `NoExecute`
  * 테인트 `NoExecute` - 톨러레이션 `NoSchedule`

### 참고

* [https://kubernetes.io/ko/docs/concepts/scheduling-eviction/taint-and-toleration/](https://kubernetes.io/ko/docs/concepts/scheduling-eviction/taint-and-toleration/)
