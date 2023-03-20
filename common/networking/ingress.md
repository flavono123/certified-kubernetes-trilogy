# Ingress

인그레스(Ingress)는 규칙 기반으로 서비스를 클러스터 바깥에 HTTP 외부 URL로써 노출합니다.

그러기 위해선 인그레스 컨트롤러와 로드밸런서가 필요합니다. 하지만 시험을 준비하는데 이를 직접 설치할 필요는 없습니다. 제공해드리는 실습 환경처럼, 시험에서도 이 부분은 프로비저닝 되어 있기 때문에(인그레스 컨트롤러: [ingress-nginx](https://github.com/kubernetes/ingress-nginx)) 인그레스 자체에만 집중해서 알아봅시다.

인그레스는 규칙에 따라 서비스로 라우팅 할 수 있고, 규칙은 호스트나 경로를 포함합니다. 실습은 경로에 따라 nginx 또는 httpd로 라우팅하는 인그레스를 만들어 보겠습니다.

먼저, nginx와 httpd의 디플로이먼트와 서비스를 각각 만듭니다.

```shell
$ k create deploy nginx --image=nginx --replicas=3
deployment.apps/nginx created
$ k create deploy httpd --image=httpd --replicas=3
deployment.apps/httpd created
$ k expose deploy nginx --port 80
service/nginx exposed
$ k expose deploy httpd --port 80
service/httpd exposed
$ k get deploy,svc
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/httpd   3/3     3            3           31s
deployment.apps/nginx   3/3     3            3           42s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/httpd        ClusterIP   10.107.14.158   <none>        80/TCP    4s
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   22h
service/nginx        ClusterIP   10.104.11.74    <none>        80/TCP    8s
$ curl 10.104.11.74
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
$ curl 10.107.14.158
<html><body><h1>It works!</h1></body></html>

```

Check responses of nginx and httpd are differ.&#x20;

nginx와 httpd의 응답이 다른 것을 확인합니다.

Now create a Ingress named `webservers`.

이번엔 `webservers` 라는 이름의 인그레스를 만듭니다.

```shell
$ k create ing webservers --rule "/nginx=nginx:80" --rule "/httpd=httpd:80" --class nginx
ingress.networking.k8s.io/webservers created
$ k annotate ing webservers nginx.ingress.kubernetes.io/rewrite-target='/'
ingress.networking.k8s.io/webservers annotated
```

* &#x20;`--rule` 플래그의 문법은 `host/path=service:port` 입니다.
  * 라우트를 호스트로 특정하지 않고 IP로 요청할 것이기 때문에 비워두었습니다.
  * `/nginx` 경로의 요청은 `nginx` 서비스, 80 포트로 요청합니다.
  * `/httpd` 경로의 요청은 `httpd` 서비스, 80 포트로 요청합니다
* 어노테이션 `nginx.ingress.kubernetes.io/rewrite-target: /` 요청 경로를 `/` 로 바꿉니다.
  * 만약 요청한 경로가 `/nginx` 이라면, 인그레스에서 `nginx` 서비스에 `/` 경로로 요청합니다.
  * 만약 요청한 경로가 `/httpd/index.html` 이라면, 인그레스에서 `httpd` 서비스에`/`경로로 요청합니다.

For an Ingress, an imperative creation seems complex. Generating a manifest and applying it would be better way. You can check the similar declaration from the created Ingress above.

명령적 방법으로 인그레스를 만드는건 플래그가 복잡합니다. 문서에서 매니페스트 템플릿을 복사해서 사용합시다. `$do` 으로 생성해보면 `--rule` 플래그가 해당하는 스펙 키를 쉽게 확인할 수 있습니다.

```shell
# Exercise to refer the documentation when you cannot remember the all command option.
# And always check help messages(-h, --help)
$ k create ing webservers --rule "/nginx=nginx:80" --rule "/httpd=httpd:80" --class nginx $do
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  creationTimestamp: null
  name: webservers
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - backend:
          service:
            name: nginx
            port:
              number: 80
        path: /nginx
        pathType: Exact
      - backend:
          service:
            name: httpd
            port:
              number: 80
        path: /httpd
        pathType: Exact
status:
  loadBalancer: {}

$ k create ing webservers --rule "/nginx=nginx:80" --rule "/httpd=httpd:80" --class nginx --dry-run=client -oyaml > ing-webservers.yaml
$ vi ing-webservers.yaml
# Add the annotation
$ k apply -f ing-webservers.yaml
```

In `.spec.rules[]`, one element(HTTP, no host) has two paths we defined. the `.spec.rules[].paths[].backend` and fields are intuitive, matching to the Services and the paths for that.

`spec.rules[0].http` 에서 경로(`paths`)를 규칙으로 분기합니다(호스트를 규칙에 포함하지 않아, `host` 필드 없이, 하나만 있습니다). `spec.rules[].http.paths[].backend` 는, 딱 보면 알 수 있듯, 서비스와 매칭하는 객체입니다.

`spec.rules[].http.paths[].pathType` 경로 매칭과 관련한 필드이고 다음 두가지가 있습니다.

* `Exact` 는 정확히 경로와 일치해야 합니다(대소문자 포함).
* `Prefix` 는, '/'로 구분된, 접두사 기반 매칭을 합니다. [예시](https://kubernetes.io/docs/concepts/services-networking/ingress/#examples)를 확인하세요.

몇 초 후, 인그레스는 IP를 할당 받습니다. 실습 환경에선 노드 CIDR의 IP를 받도록 했습니다.

```shell
$ k get ing -w
NAME         CLASS   HOSTS   ADDRESS   PORTS   AGE
webservers   nginx   *                 80      47s
webservers   nginx   *       192.168.1.10   80      58s

```

인그레스에 요청하여 동작을 검증해봅시다.

```shell
$ curl 192.168.1.10/nginx
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
$ curl 192.168.1.10/httpd
<html><body><h1>It works!</h1></body></html>

```

실습을 정리합니다.

```shell
$ k delete ing webservers
ingress.networking.k8s.io "webservers" deleted
$ k delete deploy nginx httpd
deployment.apps "nginx" deleted
deployment.apps "httpd" deleted
$ k delete svc nginx httpd
service "nginx" deleted
service "httpd" deleted
$ k get ing,svc,deploy
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   23hl

```

### 정리

* 인그레스는 클러스터 외부 요청을 내부의 규칙에 따라 서비스로 라우팅한다.
* 인그레스 규칙은 호스트, 경로 그리고 경로 매칭 타입과 백엔드 서비스로 정의한다.

### 실습



### 참고

* [https://kubernetes.io/docs/concepts/services-networking/ingress/](https://kubernetes.io/docs/concepts/services-networking/ingress/)
* [https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
