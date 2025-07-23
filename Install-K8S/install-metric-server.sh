#!/bin/bash
mkdir metrics-server && cd metrics-server
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm pull metrics-server/metrics-server --version 3.12.2
tar -xzf metrics-server-3.12.2.tgz
cd metrics-server
echo "args:
  - --kubelet-insecure-tls" >> values.yaml
helm install metric-server metrics-server -n kube-system
kubectl top nodes
