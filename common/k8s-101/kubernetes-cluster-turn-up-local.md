---
description: 더 이상 지원하지 않습니다. Kubernetes Cluster Turn up GCP로 실습하세요.
---

### ⚠️DEPRECATED!: Kubernetes Cluster Turn up(Local)
Vagrant + Ansible을 사용한 로컬 클러스터 구성은 더 이상 지원하지 않습니다. [Kubernetes Cluster Turn up(GCP)](common/k8s-101/kubernetes-cluster-turn-up-gcp.md)으로 실습하세요.
### Prerequisuite

#### macOS

#### Install Ansible

```shell
$ pip3 install ansible

# Set PATH to use Python3 package binaries
$ export PATH="/Users/$USER/Library/Python/$(python3 --version | cut -d' ' -f2 | grep -oe '\d\.\d')/bin:$PATH"

# Confirm the installation
$ ansible --version
```

#### Install Vagrant

```shell
$ brew install vagrant virtualbox

# Confirm installations
$ vagrant -v
Vagrant 2.3.2

$ virtualbox
# (... The gui application would be launched, ctrl-c to exit it)

# Set the CIDR for host-only adapter
# ref. https://www.virtualbox.org/manual/ch06.html#network_hostonly
$ echo "* 10.0.0.0/8" | sudo tee /etc/vbox/networks.conf
* 10.0.0.0/8
```

### Turn up

```shell
$ git clone https://github.com/flavono123/kubernetes-the-hard-way.git
$ cd kubernetes-the-hard-way
$ vagrant up

$ vagrant ssh node-1
# (in the control plane node)
vagrant@node-1~: sudo -i
root@node-1~: k get po
```
