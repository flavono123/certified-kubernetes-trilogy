<details>
<summary>

In Namespace `default`, create a NetworkPolicy named `np1` which restricts outgoing tcp connections from Deployment `frontend` and only allows those going to Deployment `api`. Make sure the NetworkPolicy still allows outgoing traffic on UDP/TCP ports 53 for DNS resolution.

Test using: `wget www.google.com` and `wget api:2222` from a Pod of Deployment frontend.

</summary>

</details>

**문제 준비: `k apply -f raw.githubusercontent.com/flavono123/certified-kubernetes-trilogy/main/resources/manifests/ckad/service-and-networking/problem1.yaml`**
