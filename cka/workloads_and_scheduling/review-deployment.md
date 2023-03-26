# (Review) Deployments

> 📘 Cluster: **k8s**(default)
<br> `vagrant provision` 또는
<br> `vagrant destroy -f && vagrant up`

<details>
<summary><b>1. Deployments</b>
<br> <code>nginx</code> 컨테이너 이미지를 사용해 <code>nginx</code> 이름의 디플로이먼트를 만드세요.
<br> - 레플리카 수: 3
<br> - 컨테이너 포트: 80
</summary>
<pre><code># 매니페스트 생성 후 apply
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
</code></pre>
또는
<pre><code>$ k create deploy nginx --image=nginx --replicas=3 --port=80
</code></pre>
</details>

<details>
<summary><b>2. Scale up/down</b>
<br> <code>nginx</code> 디플로이먼트의 레플리카 수를 5로 늘리세요.
</summary>
<pre><code>$ k scale deploy nginx --replicas=5
</code></pre>
또는
<pre><code>$ k patch deploy nginx -p '{"spec":{"replicas":5}}'
$ k edit deploy nginx
# spec.replicas 수정
</code></pre>

</details>

<details>
<summary><b>3. Rollout</b>
<br> <code>nginx</code> 디플로이먼트의 이미지를 <code>nginx:1.14</code>로 업데이트하세요.
</summary>
<pre><code>$ k set image deploy nginx nginx=nginx:1.14
</code></pre>
또는
<pre><code>$ k edit deploy nginx
# spec.template.spec.containers[0].image 수정
</code></pre>
</details>

<details>
<summary><b>4. Rollback</b>
<br> <code>nginx</code> 디플로이먼트의 이미지를 <code>nginx</code>로 롤백하세요.
</summary>
<pre><code>$ k rollout undo deploy nginx
</code></pre>

</details>

<details>
<summary><b>5. Update Strategy</b>
<br> <code>nginx</code> 디플로이먼트의 업데이트 전략을 <code>Recreate</code>로 변경하세요.
</summary>
<pre><code># 매니페스트 수정 후 apply
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  strategy:
    type: Recreate  # 수정
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.13
        ports:
        - containerPort: 80
</pre></code>
또는
<pre><code>$ k edit deploy nginx
# spec.strategy.type 수정
</code></pre>
</details>

