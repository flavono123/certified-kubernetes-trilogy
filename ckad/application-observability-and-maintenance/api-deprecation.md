# API Deprecations

## Deprecated API
현재 쿠버네티스 서버 버전에서 deprecated 된 버전의 API를 사용하면 경고(warning)가 발생합니다.

```yaml
apiVersion: flowcontrol.apiserver.k8s.io/v1beta2
kind: FlowSchema
metadata:
  name: example
spec:
  priorityLevelConfiguration:
    name: system-node-critical
  matchingPrecedence: 100
  rules:
  - nonResourceRules:
    - nonResourceURLs:
      - "/healthz"
      verbs:
      - "*"
    subjects:
    - kind: Group
      group:
        name: "system:unauthenticated"
```
`FlowSchema`는 `v1beta2`에서 deprecated 되었기 때문에 경고가 발생합니다:

```sh
$ k apply -f flow-schema.yaml
Warning: flowcontrol.apiserver.k8s.io/v1beta2 FlowSchema is deprecated in v1.26+, unavailable in v1.29+; use flowcontrol.apiserver.k8s.io/v1beta3 FlowSchema
flowschema.flowcontrol.apiserver.k8s.io/example created
```

Warning message에 사용해야할 버전을 알려주고 있습니다(`use flowcontrol.apiserver.k8s.io/v1beta3 FlowSchema`). 또 사용해야 할 버전은 문서를 통해서도 유추할 수 있고, `kubectl explain` 명령으로 리소스의 현재 지원하는 API 버전을 확인하여 유추할 수도 있습니다.

```sh
$ k explain flowschema
KIND:     FlowSchema
VERSION:  flowcontrol.apiserver.k8s.io/v1beta3
...
```


`apiVersion`을 `flowcontrol.apiserver.k8s.io/v1beta3`로 바꿔주어 문제를 해결합니다.

## 삭제된 API

현재 쿠버네티스 서버 버전에서 삭제된 버전의 API를 사용하면 오류가 발생합니다.

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure
```

`batch/v1beta1`은 `v1.22`에서 삭제된 API이기 때문에 오류가 발생합니다:

```sh
$ k apply -f cronjob.yaml
error: resource mapping not found for name: "hello" namespace: "" from "STDIN": no matches for kind "CronJob" in version "batch/v1beta1"
ensure CRDs are installed first
```

역시 `kubectl explain` 으로 현재 지원하는 API 버전을 확인할 수 있습니다:

```sh
$ k explain cj
KIND:     CronJob
VERSION:  batch/v1
...
```

`apiVersion`을 `batch/v1`로 바꿔주어 문제를 해결합니다.
