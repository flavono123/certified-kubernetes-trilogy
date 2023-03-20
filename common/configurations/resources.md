# Resources

Specifying Pods, you may set requests and limits for resources, such as CPU and memory, to containers.

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: resource
  name: resource
spec:
  containers:
  - image: nginx
    name: resource
    resources:
      requests:
        cpu: 500m
        memory: 128Mi
      limits:
        cpu: 1
        memory: 256Mi
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Check the field `spec.containers[0].resources` in the manifest of example Pod above.

CPU and memory uses different units.

#### CPU resource units

* `1` stands for one virtual core.
* Fractional units are supported like `0.5`.
* postfix `m` stands for milli, one of a thousand, so `500m` is equal to `0.5`

#### Memory resource units

* Integers
* Or quantity suffixes, decimal and binary
  * Decimal
    * `K`(kilo) - 1,000 (10^3)
    * `M`(mega) - 1,000,000 (10^6)
    * `G`(giga) - 1,000,000,000 (10^9)
  * Binary
    * `Ki`(kibi) - 1,024 (2^10)
    * `Mi`(mebi) - 1,048,576 (2^20)
    * `Gi`(gibi) - 1,073,741,824 (2^30)

Therefore, requested mount of memory is 128 **mebi**bytes

#### Requests and limits

Kubelet and container runtime prevent the containers using resources more than limits. 컨테이너가 CPU를 `limits` 보다 더 쓴다면 kubelet 또는 컨테이너 런타임이, 실행됮 않도록, 스로틀 할 것 입니다. 하지만 메모리가 `limits`를 초과한다면 메모리 부족(OOM)으로 컨테이너를 죽일 것 입니다.

### 정리

* 컨테이너의 CPU와 메모리 자원 요청량과 한계치를 파드에 정의할 수 있다.
  * 요청량(requests): 파드 `spec.containers[].resources.requests`
  * 한계치(limits): 파드 `spec.containers[].resources.limits`
* 1 CPU는 한 개의 가상 코어를 의미하고 1/1000(milli)까지 표현할 수 있다.
* 메모리는 정수와 십진(킬로, 메가, 기가, ...) 또는 이진(키비, 메비, 기비, ...) postfix로 표현할 수 있다.

### 참고

* [https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
* [https://kubernetes.io/ko/docs/concepts/configuration/manage-resources-containers/](https://kubernetes.io/ko/docs/concepts/configuration/manage-resources-containers/)

### 실습



