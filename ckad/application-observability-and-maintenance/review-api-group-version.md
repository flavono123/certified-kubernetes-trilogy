<details>
<summary>

Q1. 클러스터의 Deployment API 그룹과 버전을 확인하세요.
</summary>

```sh
$ k explain deployment
KIND:     Deployment
VERSION:  apps/v1
...

$ k api-resources | grep deployment
deployments                       deploy                                          apps/v1                                true         Deployment
```

</details>

<details>
<summary>

Q2. 클러스터에서 사용 중인 모든 API 버전을 출력하세요.
</summary>

```sh
$ k api-versions
```

</details>

<details>
<summary>

Q3. 클러스터의 모든 네임스페이스 리소스를 출력하세요.
</summary>

```sh
$ k api-resources --namespaced=true
```
</details>

<details>
<summary>

Q4. 클러스터의 API 그룹 `apps`의 모든 리소스 이름을 출력하세요.
</summary>

```sh
$ k api-resources --api-group=apps -oname
```

</details>

<details>
<summary>

Q5. 클러스터의 모든 네임스페이스 리소스를 `kind`의 알파벳 순서로 정렬해서 출력하세요.
</summary>

```sh
$ k api-resources --namespaced=true --sort-by=name
```

</details>
