#!/bin/sh

# Source: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#tear-down
kubeadm reset
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
