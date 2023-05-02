#!/bin/sh

### ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.0/deploy/static/provider/baremetal/deploy.yaml

### metrics-server
# helm upgrade --install metrics-server metrics-server \
#   -n kube-system --create-namespace \
#   --repo https://kubernetes-sigs.github.io/metrics-server

### metallb
wget -qO- https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml | \
  sed 's/failurePolicy: Fail/failurePolicy: Ignore/' | \
  kubectl apply -f -

sleep 40 # wait for metallb to be ready

kubectl apply -f https://raw.githubusercontent.com/flavono123/certified-kubernetes-trilogy/main/resources/gcloud-setup/l2conf.yaml

### sc: local-path
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.22/deploy/local-path-storage.yaml
# kubectl annotate storageclass local-path storageclass.kubernetes.io/is-default-class=true

### sc: nfs-subdir-external-provisioner
helm upgrade --install nfs-provisioner nfs-subdir-external-provisioner \
  -n nfs-provisioner --create-namespace \
  --repo https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner \
  --set nfs.path=/nfs-storage,nfs.server="$(ip addr show ens4 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)" \
  --set nodeSelector."kubernetes\.io/hostname"="$(hostname)" \
  --set tolerations[0].key="node-role.kubernetes.io/control-plane",tolerations[0].operator="Exists",tolerations[0].effect="NoSchedule"
