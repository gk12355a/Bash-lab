#!/bin/bash
# Cài đặt Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh



# Cài Cilium chart
helm repo add cilium https://helm.cilium.io/
helm pull cilium/cilium --version 1.16.0
tar -xzvf cilium-1.16.0.tgz
mv cilium cilium-chart
cd cilium-chart

# Tạo values-cilium.yaml
cat <<EOF > values-cilium.yaml
cluster:
  name: kubernetes
hubble:
  enabled: true
  metrics:
    enableOpenMetrics: true
    enabled:
    - dns
    - drop
    - tcp
    - flow
    - port-distribution
    - icmp
    - httpV2
  relay:
    nodeSelector:
      workertype: monitor
    tolerations:
      - key: workertype
        operator: Equal
        value: monitor
    enabled: true
    service:
      type: NodePort
  ui:
    enabled: true
    service:
      type: NodePort
    nodeSelector:
      workertype: monitor
    tolerations:
      - key: workertype
        operator: Equal
        value: monitor
k8sServiceHost: 192.168.23.111
k8sServicePort: 6443
operator:
  prometheus:
    enabled: true
  replicas: 1
  unmanagedPodWatcher:
    restart: true
prometheus:
  enabled: true
serviceAccounts:
  cilium:
    name: cilium
  operator:
    name: cilium-operator
tunnel: vxlan
EOF
cd ..
# Cài Cilium CLI
wget https://github.com/cilium/cilium-cli/releases/download/v0.15.0/cilium-linux-amd64.tar.gz
tar -xzvf cilium-linux-amd64.tar.gz
sudo cp cilium /usr/bin/
sudo chmod +x /usr/bin/cilium
# Gán nhãn cho worker node
kubectl label node npd-worker2 workertype=monitor

# Cài đặt Cilium
helm install cilium cilium-chart --namespace kube-system --values values-cilium.yaml
cilium status