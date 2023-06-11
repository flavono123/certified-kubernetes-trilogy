<details>
<summary>

In Namespace `default` you'll find two Deployments named api and frontend. Both Deployments are exposed inside the cluster using Services. Create a NetworkPolicy named `np1` which restricts outgoing tcp connections from Deployment `frontend` and only allows those going to Deployment `api`. Make sure the NetworkPolicy still allows outgoing traffic on UDP/TCP ports 53 for DNS resolution.

Test using: `wget www.google.com` and `wget api:2222` from a Pod of Deployment frontend.

</summary>


```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np1
  namespace: venus
spec:
  podSelector:
    matchLabels:
      id: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          id: api
  - ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
```
</details>

**문제 준비: `k apply -f raw.githubusercontent.com/flavono123/certified-kubernetes-trilogy/main/resources/manifests/ckad/service-and-networking/problem1.yaml`**
