# Problem 1: Workloads and Scheduling

<details>
<summary>

Create *Namespace* <code>enuma-elish</code> for the following then use it. Create a <i>Deployment</i> named <code>deploy-important</code> with label <code>en=lil</code> (the <i>Pods</i> should also have this label) and 3 replicas. It should contain two containers, the first named <code>container1</code> with image <code>nginx:1.17.6-alpine</code> and the second one named <code>container2</code> with image <code>kubernetes/pause</code>.
<br><br>

There should be <b>only ever one <i>Pod</i> of that <i>Deployment</i> running on one worker node</b>. We have two worker nodes: <code>node-2</code> and <code>node-3</code>. Because the <i>Deployment</i> has three replicas the result should be that on both nodes one <i>Pod</i> is running. The third <i>Pod</i> won't be scheduled, unless a new worker node will be added.
<br><br>

In a way we kind of simulate the behaviour of a *DaemonSet* here, but using a *Deployment* and a fixed number of replicas.</summary>

```sh
# create namespace
$ k create ns enuma-elish
```

```yaml
# apply this
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-important
  namespace: enuma-elish
spec:
  replicas: 3
  selector:
    matchLabels:
      en: lil
  template:
    metadata:
      labels:
        en: lil
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: en
                operator: In
                values:
                - lil
            topologyKey: kubernetes.io/hostname
      containers:
      - name: container1
        image: nginx:1.17.6-alpine
      - name: container2
        image: kubernetes/pause
```

\* 파드 안티어피니티 참고: https://kubernetes.io/ko/docs/concepts/scheduling-eviction/assign-pod-node/#more-practical-use-cases

</details>

