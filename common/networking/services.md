# Services

_서비스(Services)_는 워크로드를 네트워크에 노출합니다.

먼저 서비스로 노출할 워크로드, 디플로이먼트를 만들어 봅시다.

```shell
$ k create deploy nginx-hostname --image=vonogoru123/nginx-hostname --replicas=3
deployment.apps/nginx-hostname created
$ k get po
NAME                              READY   STATUS    RESTARTS   AGE

```

<mark style="color:purple;">nginx-hostname-65d9695c69-g67cz 1/1 Running 0 7m41s</mark>\
<mark style="color:green;">nginx-hostname-65d9695c69-n4fqd 1/1 Running 0 7m41s</mark>\
<mark style="color:orange;">nginx-hostname-65d9695c69-ps2m7 1/1 Running 0 7m41s</mark>

[`vonogoru123/nginx-hostname`](https://github.com/flavono123/nginx-hostname) 는 루트 경로(/) 응답을 호스트 이름(=파드 이름)을 응답하는 nginx 커스텀 이미지입니다.

`expose` 명령을 사용해 디플로이먼트와 같은 이름의 서비스를 노출합니다.

```shell
$ k expose deployment nginx-hostname --port 80 --target-port 80
service/nginx-hostname exposed
$ k get svc nginx-hostname
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
nginx-hostname   ClusterIP   10.96.235.110   <none>        80/TCP    2s
```

서비스 IP(10.96.235.110)에 열번 요청해봅시다.

```shell
$ for i in {1..10}; do curl 10.96.235.110; done
```

<mark style="color:orange;">nginx-hostname-65d9695c69-ps2m7</mark>\ <mark style="color:orange;">nginx-hostname-65d9695c69-ps2m7</mark>\ <mark style="color:orange;">nginx-hostname-65d9695c69-ps2m7</mark>\
<mark style="color:purple;">nginx-hostname-65d9695c69-g67cz</mark>\
<mark style="color:green;">nginx-hostname-65d9695c69-n4fqd</mark>\
<mark style="color:purple;">nginx-hostname-65d9695c69-g67cz</mark>\
<mark style="color:green;">nginx-hostname-65d9695c69-n4fqd</mark>\
<mark style="color:purple;">nginx-hostname-65d9695c69-g67cz</mark>\ <mark style="color:purple;">nginx-hostname-65d9695c69-g67cz</mark>\
<mark style="color:orange;">nginx-hostname-65d9695c69-ps2m7</mark>

서비스는 노출한 워크로드의 파드에 로드 밸런싱 하는 것을 확인할 수 있습니다. 이런식으로 디플로이먼트의 고가용성을 서비스로 제공할 수 있습니다.

#### DNS

IP는 좋은 서비스 디스커버리 방법이 아닙니다. 서비스는 클러스터 안에서 도메인 이름으로 노출됩니다.

클러스터 내에서 서비스에 요청할 수 있도록 파드를 생성합니다.

<pre class="language-shell"><code class="lang-shell"><strong>$ k run test --image=curlimages/curl -it --rm --restart=Never -- sh
</strong>If you don't see a command prompt, try pressing enter.
/ $ for i in $(seq 1 10); do curl nginx-hostname; done
# coloring the outputs
</code></pre>

<mark style="color:orange;">nginx-hostname-65d9695c69-ps2m7</mark>\
<mark style="color:green;">nginx-hostname-65d9695c69-n4fqd</mark>\ <mark style="color:green;">nginx-hostname-65d9695c69-n4fqd</mark>\
<mark style="color:purple;">nginx-hostname-65d9695c69-g67cz</mark>\ <mark style="color:purple;">nginx-hostname-65d9695c69-g67cz</mark>\
<mark style="color:green;">nginx-hostname-65d9695c69-n4fqd</mark>\ <mark style="color:green;">nginx-hostname-65d9695c69-n4fqd</mark>\
<mark style="color:purple;">nginx-hostname-65d9695c69-g67cz</mark>\
<mark style="color:orange;">nginx-hostname-65d9695c69-ps2m7</mark>\
<mark style="color:purple;">nginx-hostname-65d9695c69-g67cz</mark>

새롭게 나온 `run` 명령 플래그에 대해 알아봅니다.

* `-it` : 파드 컨테이너에 표준 출력으로 붙습니다.
* `--rm` : 컨테이너 실행 후 파드를 삭제합니다.
* `--restart=Never` : 파드 재시작 정책을 변경합니다(default `Always`)

위 플래그는 컨테이너에 쉘로 접속하고 종료 후에 파드를 삭제하기 위해 많이 사용합니다. 플래그들을 통째로 외우면 편합니다.

IP가 아닌 서비스 이름, `nginx-hostname` 으로 요청했는데 응답이 왔습니다. 어떻게 가능할까요?

모든 파드의 /etc/resolv.conf엔 DNS 서버가 있습니다.

```shell
$ k run test --image=curlimages/curl --rm --restart=Never -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

10.96.0.10은 클러스터의 DNS 서버인 `kube-dns` 입니다. 파드는 요청할 때 여기로 DNS 쿼리를 합니다.&#x20;

```shell
$ k get svc -n kube-system
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   6h52m

```

DNS 서버에 등록되는 서비스 도메인 이름 포맷은 `<svc>.<ns>.svc.<cluster_domain>`:

* `<svc>`: 서비스 이름 (e.g. `nginx-hostname`)
* `<ns>`: 네임스페이스 (e.g. `default`)
* `<cluster_domain>`: 클러스터 도메인 (e.g. `cluster.local`)

따라서 예제 서비스의 FQDN은 `nginx-hostname.default.svc.cluster.local` 입니다. search에 있는 `default.svc.cluster.local` 로 확장 가능하므로 서브 도메인 `nginx-hostname` 만 써도 요청이 성공합니다.

다른 네임스페이스의 서비스로 요청하려면, `another-svc.another-ns` 처럼 네임스페이스까지 서브 도메인을 명시해야 합니다. 이 DNS 쿼리는 `svc.cluster.local` 도  search 도메인에 있기 때문에 가능합니다.



### NodePort

위에서 만든, `ClusterIP` 서비스는 클러스터 내의 네트워크에서만 쓰일 수 있습니다. 클러스터 바깥에서 요청할 수 있도록 `NodePort` 라는 다른 타입의 서비스를 노출할 수 있습니다.

앞선 디플로이먼트를 `NodePort` 서비스로 노출해봅시다.

```shell
$ k expose deploy nginx-hostname --name nginx-nodeport --port 80 --target-port 80 --type=NodePort
service/nginx-nodeport exposed
$ k get svc nginx-nodeport
NAME             TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-nodeport   NodePort   10.110.65.105   <none>        80:30940/TCP   6s
$ k get svc nginx-nodeport -oyaml | yq .spec.ports[0].nodePort
30940
```

30940번 포트가 서비스에 nodePort로 할당되었습니다. nodePort는, 기본으로, 30000-32767 범위에서 할당되기 때문에, 여러분 환경에선 다른 포트가 할당되었을 수 있습니다. 또는 `.spec.ports[].nodePort` 를 범위 내에서 작성하거나 수정하여 지정할 수도 있습니다. 이 포트가 모든 클러스터의 노드에서 사용하여, 클러스터 바깥에서 노드 IP와 nodePort로 서비스를 노출합니다.&#x20;

노드 IP와 nodePort에 대해 요청하면 응답을 볼 수 있습니다.

```
$ curl 192.168.1.3:30940
nginx-hostname-65d9695c69-n4fqd
$ curl 192.168.1.4:30940
nginx-hostname-65d9695c69-g67cz
```

실습한 내용을 정리합니다.

```shell
$ k delete svc nginx-hostname nginx-nodeport
service "nginx-hostname" deleted
service "nginx-nodeport" deleted
$ k delete deploy nginx-hostname
deployment.apps "nginx-hostname" deleted
```

### 정리

* 서비스는 디플로이먼트, 레플리카셋, 파드와 같은 워크로드를 네트워크에 노출합니다.
* 서비스는, FQDN `<svc>.<ns>.svc.<cluster-domain>`  의 도메인 이름이 클러스터 내에 등록됩니다.
* The default type of Services is `ClusterIP` which is exposed on the cluster network only.
* `ClusterIP` 는 클러스터 내에서만 노출되는 서비스의 기본 타입입니다.
* `NodePort` 는  클러스터 바깥으로도 노출하는 서비스  타입입니다.

### 실습

### 참고

* [https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/)
* [https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)



