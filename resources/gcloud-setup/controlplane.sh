#!/bin/sh

# Source: http://kubernetes.io/docs/getting-started-guides/kubeadm

set -e

source /etc/lsb-release
if [ "$DISTRIB_RELEASE" != "20.04" ]; then
    echo "################################# "
    echo "############ WARNING ############ "
    echo "################################# "
    echo
    echo "This script only works on Ubuntu 20.04!"
    echo "You're using: ${DISTRIB_DESCRIPTION}"
    echo "Better ABORT with Ctrl+C. Or press any key to continue the install"
    read
fi


KUBE_VERSION=1.26.1

### setup terminal
apt-get update
apt-get install -y bash-completion binutils
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias c=clear' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc

### disable linux swap and remove any existing swap partitions
swapoff -a
sed -i '/\sswap\s/ s/^\(.*\)$/#\1/g' /etc/fstab


### remove packages
kubeadm reset -f || true
crictl rm --force $(crictl ps -a -q) || true
apt-mark unhold kubelet kubeadm kubectl kubernetes-cni || true
apt-get remove -y docker.io containerd kubelet kubeadm kubectl kubernetes-cni || true
apt-get autoremove -y
systemctl daemon-reload



### install podman
. /etc/os-release
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:testing.list
curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add -
apt-get update -qq
apt-get -qq -y install podman cri-tools containers-common
rm /etc/apt/sources.list.d/devel:kubic:libcontainers:testing.list
cat <<EOF | sudo tee /etc/containers/registries.conf
[registries.search]
registries = ['docker.io']
EOF

### install distribution

# install docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# write append "127.0.0.1 private-registry.io"  to /etc/hosts if not exists
if ! grep -q "private-registry.io" /etc/hosts; then
  echo "127.0.0.1 private-registry.io" >> /etc/hosts
fi

cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries" : ["http://private-registry.io:5000"]
}
EOF

rm -rf certs/*
mkdir -p certs
openssl req \
  -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key \
  -addext "subjectAltName = DNS:myregistry.domain.com" \
  -x509 -days 365 -out certs/domain.crt \
  -subj "/CN=private-registry.io"
cp certs/domain.crt /usr/local/share/ca-certificates/private-registry.io.crt
mkdir -p /etc/docker/certs.d/private-registry.io:5000
cp certs/domain.crt /etc/docker/certs.d/private-registry.io:5000/ca.crt
cp certs/domain.crt /etc/docker/certs.d/private-registry.io:5000/domain.cert
cp certs/domain.key /etc/docker/certs.d/private-registry.io:5000/domain.key

systemctl daemon-reload
systemctl restart docker

mkdir -p auth
docker run \
  --entrypoint htpasswd \
  httpd:2 -Bbn testuser testpassword > auth/htpasswd
docker rm -f registry || true
docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry \
  -v "$(pwd)"/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -v "$(pwd)"/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2

podman login private-registry.io:5000 -u testuser -p testpassword --tls-verify=false

### install packages
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
mkdir -p /etc/apt/keyrings
curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
retries=5
for _ in $(seq 1 $retries); do
    if apt-get update; then
        break
    else
      sleep 5
    fi
done
apt-get install -y docker.io containerd kubelet=${KUBE_VERSION}-00 kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00 kubernetes-cni
apt-mark hold kubelet kubeadm kubectl kubernetes-cni


### install containerd 1.6 over apt-installed-version
wget https://github.com/containerd/containerd/releases/download/v1.6.12/containerd-1.6.12-linux-amd64.tar.gz
tar xvf containerd-1.6.12-linux-amd64.tar.gz
systemctl stop containerd
mv bin/* /usr/bin
rm -rf bin containerd-1.6.12-linux-amd64.tar.gz
systemctl unmask containerd
systemctl start containerd


### containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
sudo mkdir -p /etc/containerd


### containerd config
cat > /etc/containerd/config.toml <<EOF
disabled_plugins = []
imports = []
oom_score = 0
plugin_dir = ""
required_plugins = []
root = "/var/lib/containerd"
state = "/run/containerd"
version = 2

[plugins]

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      base_runtime_spec = ""
      container_annotations = []
      pod_annotations = []
      privileged_without_host_devices = false
      runtime_engine = ""
      runtime_root = ""
      runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        BinaryName = ""
        CriuImagePath = ""
        CriuPath = ""
        CriuWorkPath = ""
        IoGid = 0
        IoUid = 0
        NoNewKeyring = false
        NoPivotRoot = false
        Root = ""
        ShimCgroup = ""
        SystemdCgroup = true
EOF


### crictl uses containerd as default
{
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF
}


### kubelet should use containerd
{
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS="--container-runtime remote --container-runtime-endpoint unix:///run/containerd/containerd.sock"
EOF
}



### start services
systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd
systemctl enable kubelet && systemctl start kubelet


### init k8s
rm /root/.kube/config || true
kubeadm init --kubernetes-version=${KUBE_VERSION} --ignore-preflight-errors=NumCPU --skip-token-print --pod-network-cidr 172.16.0.0/16

mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config

### install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

### CNI
helm upgrade --install tigera-operator tigera-operator \
  -n tigera-operator --create-namespace \
  --repo https://projectcalico.docs.tigera.io/charts \
  --values https://raw.githubusercontent.com/flavono123/certified-kubernetes-trilogy/main/resources/gcloud-setup/charts/calico/values.yaml


# etcdctl
ETCDCTL_VERSION=v3.5.1
ETCDCTL_ARCH=$(dpkg --print-architecture)
ETCDCTL_VERSION_FULL=etcd-${ETCDCTL_VERSION}-linux-${ETCDCTL_ARCH}
wget https://github.com/etcd-io/etcd/releases/download/${ETCDCTL_VERSION}/${ETCDCTL_VERSION_FULL}.tar.gz
tar xzf ${ETCDCTL_VERSION_FULL}.tar.gz ${ETCDCTL_VERSION_FULL}/etcdctl
mv ${ETCDCTL_VERSION_FULL}/etcdctl /usr/bin/
rm -rf ${ETCDCTL_VERSION_FULL} ${ETCDCTL_VERSION_FULL}.tar.gz

### nfs
apt-get install -y nfs-kernel-server
mkdir -p /nfs-storage
chmod 777 /nfs-storage
chown nobody:nogroup /nfs-storage
echo "/nfs-storage $(ip n | grep ens4 | awk '{ print $1 }' | sed -e 's/1$/0\/24/')(rw,sync,no_subtree_check,no_root_squash)" > /tmp/exports
sudo cp /etc/exports /etc/exports.bak
sudo cp /tmp/exports /etc/exports
systemctl restart nfs-kernel-server
apt-get install -y nfs-common

### tools
apt-get update
apt-get install -y jq
snap install yq


echo
echo "### node-2에서 실행 ###"
kubeadm token create --print-join-command --ttl 0

echo
echo "### node-3에서 실행 ###"
kubeadm token create --print-join-command --ttl 0
