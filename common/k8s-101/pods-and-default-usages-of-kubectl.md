# Pods and default usages of kubectl

Enter the node-1 and login as Root:

```shell
$ vagrant ssh node-1
vagrant@node-1:~$ sudo -i
root@node-1:~# 
```

For now, this is the default CLI environment on labs where we can use the kubernetes API through `kubectl`(so remain of this documentation prints prompts just as `$`).

#### Pods

Pods are the smallest deployable units of computing that you can create and manage in Kubernetes. A pod has one or more containers.

Check pods in the cluster by a subcommand **`get`**:

```shell
$ kubectl get pods
No resources found in default namespace.
```

No pod in the cluster. List pods from the all Namespaces:

```shell
$ kubectl get pods --all-namespaces
NAMESPACE        NAME                                        READY   STATUS    RESTARTS      AGE
ingress-nginx    ingress-nginx-controller-8574b6d7c9-ldp64   1/1     Running   0             5d18h
kube-flannel     kube-flannel-ds-d2rq2                       1/1     Running   0             5d18h
kube-flannel     kube-flannel-ds-lnmvs                       1/1     Running   0             5d18h
kube-flannel     kube-flannel-ds-trj4r                       1/1     Running   0             5d18h
kube-system      coredns-565d847f94-5p5p5                    1/1     Running   0             5d18h
kube-system      coredns-565d847f94-fqbmw                    1/1     Running   0             5d18h
kube-system      etcd-node-1                                 1/1     Running   0             5d18h
kube-system      kube-apiserver-node-1                       1/1     Running   0             5d18h
kube-system      kube-controller-manager-node-1              1/1     Running   1 (10h ago)   5d18h
kube-system      kube-proxy-9ln5m                            1/1     Running   0             5d18h
kube-system      kube-proxy-j4chz                            1/1     Running   0             5d18h
kube-system      kube-proxy-vkf87                            1/1     Running   0             5d18h
kube-system      kube-scheduler-node-1                       1/1     Running   1 (10h ago)   5d18h
metallb-system   metallb-controller-99b88c55f-8csg7          1/1     Running   0             5d18h
metallb-system   metallb-speaker-9p278                       1/1     Running   0             5d18h
metallb-system   metallb-speaker-l7chx                       1/1     Running   0             5d18h
metallb-system   metallb-speaker-qjngz                       1/1     Running   0             5d18h

```

You can see pods in the other namespaces(e.g. `kube-system`, ...). They are kubernetes core components or networks so on. We'll get this later.

#### Auto-completion & Abbreviation

One of important thing in CK\* exams is a time management. Less typing, you can save more times in exams.

So we can use alias **`k`** for a long `kubectl`

```shell
$ k get pods --all-namespaces
(simillar with the upper outputs)
```

And also bash completions are supported for subcommands, options and arguments

```
$ k g<tab>(get) po<tab>(pod) --all-n<tab>(--all-namespace)
(simillar with the upper outputs)
```

These are set in the real exam environment exactly same. **You don't have to configure for these on your exam!**(And also for labs)

There are also abbreviations. For instances, the `po` is for the resource name `pod(s)`, and `--all-namespace` is same `-A`&#x20;

```
$ k get po -A
(simillar with the upper outputs)
```

I'll let you know these things to save the time in your exams.

### The first pod

Let's create your first pod. The subcommand `run` create pods.

```shell
$ k run test --image=nginx
pod/test created
$ k get po
NAME   READY   STATUS    RESTARTS   AGE
test   1/1     Running   0          19s
```

In `default` namespace, you `test` pod is created.

A command for a pod creation, has syntax like **`k run <pod> --image=<image>`**. The container image tag for a pod is mandatory.

#### `describe`

You can check more details on the pod by **`describe`** subcommand.

```shell
$ k describe po test
(elliding the outputs ...)

$ k describe po test | tail -8
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Pulling    5m52s  kubelet            Pulling image "nginx"
  Normal  Pulled     5m49s  kubelet            Successfully pulled image "nginx" in 3.497584637s
  Normal  Created    5m48s  kubelet            Created container test
  Normal  Started    5m48s  kubelet            Started container test
  Normal  Scheduled  4m26s  default-scheduler  Successfully assigned default/test to cluster1-worker1
```

There are descriptions of events on the pod. Pull the image for that and create, schedule to the worker node `cluster1-worker1` by the scheduler.

You can check for not only pods but also other resources with `describe` subcommand for trouble shooting.

#### Imperative vs. Declarative

You created the pod above as an imperative way. There is another way to create a pod, **the declarative way**.

First, you can check the pod declaration(YAML) like this. `-o` is for output format.

```shell
$ k get po test -oyaml
apiVersion: v1
kind: Pod
metadata:
...
spec:
  containers:
  - image: nginx
  ...
status:
  ...
```

In a long YAML output, you can see the pod has a container whose image is nginx, as you created. The `spec` and `status` are stand for each a desired state and a current state.

So with that declaration, the `spec` of YAML, you can create the pod as a declarative way. Would you have to remember the long YAML, however?

NO. `kubectl` provides to create templates for that.

#### The second, 'declarative' pod

```shell
$ k run test2 --image=nginx --dry-run=client -oyaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: test2
  name: test2
spec:
  containers:
  - image: nginx
    name: test2
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

You can use the **`--dry-run=client`** flag to preview the object that would be sent to your cluster, without really submitting it.

Generate a state file through above command, then create a pod from that.

```shell
$ k run test2 --image=nginx --dry-run=client -oyaml > pod.yaml
$ k apply -f pod.yaml
pod/test2 created
$ k get pod test2
NAME    READY   STATUS    RESTARTS   AGE
test2   1/1     Running   0          11s
```

You can declare(run) a pod by subcommand **`apply`** with a declared file as a parameter for an `-f(--filename)` option.

**Choose from two methods in exams, it's about a time saving strategy.** Many tasks would be completed fast as imperative ways. Some of tasks is more efficient as declarative ways or required.

Now cleanup the labs for next.

```shell
$ k delete po test test2
pod "test" deleted
pod "test2" deleted
$ k get po
No resources found in default namespace.
```

You can delete resources by subcommand **`delete`**.

### Recap

* Use the alias, auto-completions and abbreviations to save your time.
  * Use the alias `k` rather than `kubectl` and shorter abbreviations.
  * Auto-completions are configured in the real exam, just tap!
* Run pods by a subcommand `run.`
* List resources by a subcommand `get`.
* Set the state of resources in declarative way by a subcommand `apply`.
  * Generate the YAML declaration by options `--dry-run=client -oyaml`.
* Delete resources by a subcommand `delete`.
