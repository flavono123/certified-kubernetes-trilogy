# Container Network Interface

> 📘 Cluster: **k8s**(default)
<br> `vagrant provision` 또는
<br> `vagrant destroy -f && vagrant up`

컨테이너 네트워킹 인터페이스(CNI)는 Kubernetes에서 컨테이너의 네트워크 구성을 관리하는 방법입니다. CNI 플러그인은 Kubernetes 노드와 컨테이너 사이의 네트워크 연결을 관리하며, 각 컨테이너에 IP 주소와 같은 필수 네트워크 구성 요소를 제공합니다. 이러한 CNI 플러그인은 다양한 네트워크 토폴로지 및 프로토콜을 지원하며, 특정 플러그인을 사용하여 Kubernetes 클러스터의 네트워크를 구성할 수 있습니다.

CNI 바이너리와 구성 파일의 default 경로는 각각 다음과 같습니다:
- `/opt/cni/bin/`
- `/etc/cni/net.d/`

컨트롤 플레인 노드에서 경로를 확인해 실습 클러스터에 설치한 Calico 관련한 파일을 확인할 수 있습니다:
```shell
$ ls -1 /opt/cni/bin/
bandwidth
bridge
calico
calico-ipam
dhcp
dummy
firewall
flannel
host-device
host-local
install
ipvlan
loopback
macvlan
portmap
ptp
sbr
static
tuning
vlan
vrf

$ ls -1 /etc/cni/net.d/
10-calico.conflist
calico-kubeconfig

$ cat /etc/cni/net.d/10-calico.conflist | jq
{
  "name": "k8s-pod-network",
  "cniVersion": "0.3.1",
  "plugins": [
    {
      "type": "calico",
      "datastore_type": "kubernetes",
      "mtu": 0,
      "nodename_file_optional": false,
      "log_level": "Info",
      "log_file_path": "/var/log/calico/cni/cni.log",
      "ipam": {
        "type": "calico-ipam",
        "assign_ipv4": "true",
        "assign_ipv6": "false"
      },
      "container_settings": {
        "allow_ip_forwarding": false
      },
      "policy": {
        "type": "k8s"
      },
      "kubernetes": {
        "k8s_api_root": "https://10.96.0.1:443",
        "kubeconfig": "/etc/cni/net.d/calico-kubeconfig"
      }
    },
    {
      "type": "bandwidth",
      "capabilities": {
        "bandwidth": true
      }
    },
    {
      "type": "portmap",
      "snat": true,
      "capabilities": {
        "portMappings": true
      }
    }
  ]
}
```

또는 여러 CNI 중 어떤 것을 사용 중인지, 구성 경로를 보고 확인할 수도 있습니다.
```sh
$ cat /etc/cni/net.d/10-calico.conflist | jq -r .plugins[0].type
calico
```

Calico 컴포넌트는, [오퍼레이터](https://kubernetes.io/ko/docs/concepts/extend-kubernetes/operator/)를 통해, 다음 여러 네임스페이스에 배포되어 있습니다:
- `tigera-operator`
- `calico-system`
- `calico-apiserver`

<details>
<summary>Q1. CNI 플러그인의 로그 파일 경로와 로그를 살펴보세요</summary>

```sh
$ cat /etc/cni/net.d/10-calico.conflist | jq -r .plugins[0].log_file_path
/var/log/calico/cni/cni.log
$ tail -f /var/log/calico/cni/cni.log
...
```

</details>

<details>
<summary>Q2. CNI 플러그인을 사용하는 kubeconfig 파일에서 API 서버 인증 방식을 확인해보세요</summary>

```sh
$ cat /etc/cni/net.d/10-calico.conflist | jq -r .plugins[0].kubernetes.kubeconfig
/etc/cni/net.d/calico-kubeconfig

$ cat /etc/cni/net.d/calico-kubeconfig | yq -r '.users[].user | keys'
- token
```

</details>
