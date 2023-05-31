# Helm

헬름(Helm)은 쿠버네티스 애플리케이션을 배포하기 위한 패키지 관리자입니다. 하나의 애플리케이션을 배포하기 위해서는 여러 개의 쿠버네티스 오브젝트를 생성해야 합니다. 이러한 오브젝트들을 하나의 패키지로 관리할 수 있도록 도와주는 것이 헬름입니다. 관련한 용어와 개념을 정리해보겠습니다.

## 차트
헬름 차트는 쿠버네티스 애플리케이션을 배포하기 위한 패키지입니다. 샘플 차트를 `helm` CLI 명령으로 만들 수 있습니다:
```sh
$ helm create mychart
$ ls -1 mychart/
Chart.yaml   # 차트 메타데이터
charts       # 의존 차트
templates    # 템플릿 파일
values.yaml  # 기본 설정 값
```

차트는 여러 개의 템플릿 파일과 차트를 설명하는 메타데이터로 구성됩니다. 메타데이터는 차트의 이름, 버전, 설명 등을 포함합니다.
템플릿 파일은 쿠버네티스 오브젝트를 생성하기 위한 템플릿 파일입니다. 템플릿은 go 템플릿 엔진을 사용하며 `{{ }}`와 같은 go 템플릿 문법을 사용하여 `values.yaml`의 설정 값을 참조합니다. 예를 들어 `templates/deployment.yaml` 파일은 디플로이먼트 오브젝트를 생성하기 위한 템플릿 파일입니다. 템플릿 파일은 `{{ .Values.replicaCount }}`와 같이 `values.yaml` 파일에 정의된 값을 참조할 수 있습니다.

헬름 차트의 패키징은 템플릿을 통해 길고 반복되는 쿠버네티스 매니페스트 오브젝트 작성을 줄이고, values를 통해 커스텀할 수 있게 합니다.

## 릴리즈
헬름 릴리즈는 쿠버네티스 클러스터에 차트를 설치한 것을 의미합니다. 릴리즈는 차트의 버전과 릴리즈 이름으로 구분됩니다. 최초 릴리즈 설치는 `helm install` 명령으로 할 수 있습니다. 릴리즈를 설치하기 전에, 위에서 만든 차트를 릴리즈로 설치하면 어떤 앱이 만들어지는지 살펴보기 위해 values와 템플릿 일부를 살펴봅니다:
```sh
$ head -n 10 mychart/values.yaml  | yq
# Default values for mychart.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicaCount: 1
image:
  repository: nginx
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.


$ head -n 40 mychart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "mychart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "mychart.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "mychart.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.port }}
              protocol: TCP
          livenessProbe:
```
`nginx` 이미지의 파드 하나를 생성하는 디플로이먼트 오브젝트를 만들 것을 확인했습니다.

```sh
# helm install [NAME] [CHART] [flags]
$ helm install myrelease mychart/

$ helm ls
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
myrelease       default         1               2023-05-31 12:02:38.203597221 +0000 UTC deployed        mychart-0.1.0   1.16.0

$ k get deploy
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
myrelease-mychart   1/1     1            1           34s

$ k get deploy myrelease-mychart -oyaml | yq .spec.template.spec.containers[0].image
nginx:1.16.0
```

설치된 릴리즈는 `helm ls` 명령으로 확인할 수 있습니다. 뿐만 아니라 헬름 릴리즈에 포함된 오브젝트, 디플로이먼트도 확인할 수 있습니다. values에 정의한대로 nginx 이미지의 파드 하나가 생성된 것을 확인할 수 있습니다.

만약 파드 개수를 2개로 스케일 아웃하고 싶다면, 릴리즈를 업그레이드하여 가능합니다.

```sh
$ helm upgrade myrelease mychart/ --set replicaCount=2

$ helm ls
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
myrelease       default         2               2023-05-31 12:06:27.98522775 +0000 UTC  deployed        mychart-0.1.0   1.16.0

$ k get deploy
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
myrelease-mychart   2/2     2            2           4m11s
```

릴리즈의 리비전은 2로 증가했고 파드 개수도 2개로 늘어났습니다. values를 바꿀 땐 `--set` 플래그에 키 값을 지정해주거나 내용이 적힌 YAML 파일 경로를 `--values` 로 지정하여 선언적으로 관리 할 수도 있습니다.

## 레포지토리
차트는 로컬 뿐만 아니라 원격 URL에서도 참조할 수 있습니다. 이런 원격 차트를 관리하는 곳이 헬름 레포지토리입니다. 헬름 레포지토리는 차트를 저장하고 공유하는 곳입니다. 다음 `metrics-server`의 레포지토리를 등록해봅니다:

```sh
$ helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
$ helm repo update

$ helm search repo metrics-server
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
metrics-server/metrics-server   3.10.0          0.6.3           Metrics Server is a scalable, efficient source ...

helm search repo metrics-server --versions
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
metrics-server/metrics-server   3.10.0          0.6.3           Metrics Server is a scalable, efficient source ...
metrics-server/metrics-server   3.9.0           0.6.3           Metrics Server is a scalable, efficient source ...
metrics-server/metrics-server   3.8.4           0.6.2           Metrics Server is a scalable, efficient source ...
metrics-server/metrics-server   3.8.3           0.6.2           Metrics Server is a scalable, efficient source ...
metrics-server/metrics-server   3.8.2           0.6.1           Metrics Server is a scalable, efficient source ...
metrics-server/metrics-server   3.8.1           0.6.1           Metrics Server is a scalable, efficient source ...
metrics-server/metrics-server   3.8.0           0.6.0           Metrics Server is a scalable, efficient source ...
metrics-server/metrics-server   3.7.0           0.5.2           Metrics Server is a scalable, efficient source ...
metrics-server/metrics-server   3.6.0           0.5.1           Metrics Server is a scalable, efficient source ...
metrics-server/metrics-server   3.5.0           0.5.0           Metrics Server is a scalable, efficient source ...
```
헬름 레포지토리의 URL을 이름을 특정하여 등록할 수 있습니다. `helm search repo` 명령으로 레포지토리에 등록된 차트를 검색할 수 있습니다. `--versions` 플래그를 사용하면 차트의 버전도 확인할 수 있습니다.

```sh
$ helm pull metrics-server/metrics-server --untar
$ ls metrics-server/
Chart.yaml  README.md  ci  templates  values.yaml
```

`helm pull` 명령으로 차트를 다운로드할 수 있습니다. `--untar` 플래그를 사용하면 압축을 풀어서 차트를 다운로드합니다. 다운로드한 차트 안엔 위에서 샘플로 만든 차트와 비슷한 파일로 구성돼 있습니다. 앞서 해본 것처럼 다운로드한 차트 경로를 참조해 릴리즈로 설치하거나 `<레포지토리/차트>`를 참조하여 만들 수도 있습니다.

## Values
values의 개념은 이미 설명했지만, values를 확인할 수 있는 명령 몇가지를 알아보겠습니다. 먼저 `helm get values` 명령으로 릴리즈의 values를 확인할 수 있습니다:

```sh
$ helm get values myrelease
USER-SUPPLIED VALUES:
replicaCount: 2
```

마지막에 배포한 릴리즈의 values, `--set replicaCount=2`에 대해서 확인할 수 있습니다. 또 `helm show values` 명령으로 차트의 기본 values를 확인할 수 있습니다:

```sh
$ helm show values mychart/
...
```

<details>
<summary>

Q1. 모든 네임스페이스의 설치된 헬름 릴리즈를 확인하세요.
</summary>

```sh
$ helm ls -A
```

</details>

<details>
<summary>

Q2. 네임스페이스 `kube-system`에 설치된 `metrics-server` 릴리즈의 values를 확인하세요.
</summary>

```sh
$ helm get values -n kube-system metrics-server
```
</details>
