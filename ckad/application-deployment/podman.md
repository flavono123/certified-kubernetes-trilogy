# Podman

파드맨(Podman)은, 쿠버네티스 파드에서 사용할, 컨테이너 이미지 빌드 및 레지스티리 등록(push)을 위해 사용합니다. 파드맨은 도커 CLI에 호환되는 명령어를 제공합니다. 따라서 도커를 사용해봤다면 파드맨을 사용하는데 큰 어려움은 없을 것입니다.

파드맨은 도커의 보안 취약점을 보완하기 위해 만들어졌습니다. 도커는 데몬으로 동작하고 루트 권한이 필요합니다. 하지만 파드맨은 fork and exec 모델을 사용하고 루트 권한이 필요하지 않습니다. 또한, 파드맨은 도커와 달리 데몬으로 동작하지 않습니다. 이러한 특징으로 인해 파드맨은 도커보다 더욱 안전하고 가볍습니다.

## 빌드
파드맨으로 컨테이너 이미지 빌드 실습을 하기 위해 레포지토리를 다운 받습니다.

```sh
$ git clone https://github.com/flavono123/image-build

$ ls -1 image-build/
Dockerfile
app.go
```

레포지토리 안엔 go 소스 코드 파일(app.go)과 Dockerfile이 있습니다. Dockerfile엔 app.go를 통해 컴파일된 바이너리를 실행하는 컨테이너 이미지를 빌드하는 명령어가 있습니다. 하지만 이 내용은 쿠버네티스 자격 시험의 내용은 아니므로 자세히 설명하지 않겠습니다. 그리고 파드맨은 도커에 대해 원전 호환되기 때문에 도커 파일을 그대로 사용할 수 있습니다. 따라서 다음 명령으로 컨테이너 이미지를 빌드할 수 있습니다.

```sh
$ cd image-build/
# podman build -t <이미지-태그> <컨텍스트>
$ podman build -t test-app .
# docker build -t test-app .
```

컨텍스트는 빌드할 컨테이너 이미지의 디렉토리를 의미합니다. 컨텍스트에는 Dockerfile이 포함되어야 합니다. 이미지 태그는 `<레지스트리>/<이미지-이름>:<태그>` 형식으로 지정합니다. 로컬에서만 사용할 이미지라면 레지스트리가 생략되었고 태그 역시 생략되어 이미지 이름 `test-app`만 써주었습니다. 태그를 생략하면 `latest` 태그가 자동으로 붙습니다.

```sh
$ podman images
REPOSITORY                     TAG                 IMAGE ID      CREATED        SIZE
localhost/test-app             latest              335ae1202344  3 days ago     8.04 MB
```

`podman images` 명령으로 로컬에 빌드된 이미지를 확인할 수 있습니다. 푸시도 실습해보기 위해 로컬 레지스트리를 태그 앞에 붙여 다시 이미지를 빌드합니다.

```sh
$ podman build -t private-registry.io:5000/test-app .
```

## 푸시
빌드한 이미지는 접근 가능한 레지스트리에 푸시할 수 있습니다.

```sh
$ podman build -t private-registry.io:5000/test-app .
```


<details>
<summary>

Q1. 다음 컨테이너 이미지를 만드세요.
<br> - 경로(컨텍스트): /root/image-build
<br> - 이미지 이름: `private-registry.io:5000/app`
<br> - 태그: `1.0.0`
</summary>

```sh
$ cd /root/image-build
$ podman build -t private-registry.io:5000/app:1.0.0 .
```

</details>

<details>
<summary>

Q2. 위 컨테이너 이미지를 `private-registry.io:5000` 레지스트리에 푸시하세요.
</summary>

```sh
$ podman push private-registry.io:5000/app:1.0.0
```

</details>
