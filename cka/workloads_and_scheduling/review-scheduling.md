# (Review) Node affinities, Taints and Tolerations

> 📘 Cluster: **k8s**(default)
<br> `vagrant provision` 또는
<br> `vagrant destroy -f && vagrant up`

<details>
<summary><b>1. Node affinities</b>
<br>  레이블 <code>number=2</code> 을 가진 노드에만 다음 파드를 스케쥴링 하세요.
<br> - 파드 이름: <code>two</code>
<br> - 컨테이너 이미지: <code>nginx</code>
<br> - 레이블 할 노드: <code>node-2</code>
</summary>

```sh
$ k label node node-2 number=2
$ k run two --image=nginx $do > pod-two.yaml
# pod-two.yaml 수정
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: two
spec:
  containers:
  - name: two
    image: nginx
  affinity:
    nodeAffinity: # 노드 어피티니 추가
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: number
            operator: In
            values:
            - "2"
```

</details>

<details>
<summary><b>2. Node affinities - preferred</b>
<br> <code>node-3</code>에 레이블 <code>number=3</code>을 달고 다음과 같은 노드 어피니티를 가진 파드를 스케쥴링 하세요.
<br> - 파드 이름: <code>three-over-two</code>
<br> - 컨테이너 이미지: <code>nginx</code>
<br> - <b>preferred</b> 노드 어피니티1:
<br>   - 레이블 셀렉터: <code>number=3</code>
<br>   - 가중치: <code>100</code>
<br> - <b>preferred</b> 노드 어피니티2:
<br>   - 레이블 셀렉터: <code>number=2</code>
<br>   - 가중치: <code>50</code>
</summary>

```sh
$ k label node node-3 number=3
$ k run three-over-two --image=nginx $do > pod-three-over-two.yaml
# pod-three-over-two.yaml 수정
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: three-over-two
spec:
  containers:
  - name: three-over-two
    image: nginx
  affinity:
    nodeAffinity: # 노드 어피니티 추가
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100 # 노드 어피티니 1
        preference:
          matchExpressions:
          - key: number
            operator: In
            values:
            - "3"
      - weight: 50 # 노드 어피티니 2
        preference:
          matchExpressions:
          - key: number
            operator: In
            values:
            - "2"
```

</details>

<details>
<summary><b>3. Taints</b>
<br> 노드마다 테인트를 추가하세요.
<br> - <code>node-2</code>: <code>wonder=true:NoSchedule</code>
<br> - <code>node-3</code>: <code>yonder=true:NoSchedule</code>
</summary>

```sh
$ k taint node node-2 wonder=true:NoSchedule
$ k taint node node-3 yonder=true:NoSchedule
# 확인
$ k describe node node-2 | grep Taint -A 5
$ k describe node node-3 | grep Taint -A 5
```

</details>

<details>
<summary><b>4. Taints 삭제</b>
<br> <code>node-3</code>의 테인트 <code>yonder=true:NoSchedule</code>를 삭제하세요.
</summary>

```sh
$ k taint node node-2 yonder=true:NoSchedule-
# 확인
$ k describe node node-2 | grep Taint -A 5
```

</details>

<details>
<summary><b>5. Tolerations</b>
<br> <code>node-3</code>에 파드가 스케쥴 될 수 있도록 <b>톨러레이션</b>과 <b>노드 어피니티</b>를 추가하세요.
<br> - 파드 이름: <code>must-in-two</code>
<br> - 컨테이너 이미지: <code>nginx</code>
</summary>

```sh
$ k run must-in-two --image=nginx $do > pod-must-in-two.yaml
# pod-must-in-two.yaml 수정
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: must-in-two
spec:
  containers:
  - name: must-in-two
    image: nginx
  tolerations: # 톨러레이션 추가
  - key: wonder
    operator: Exists
    effect: NoSchedule
  affinity: # 노드 어피니티 추가
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: number
            operator: In
            values:
            - "2"
```

</details>
