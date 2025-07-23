#!/bin/bash
mkdir nfs-storage && cd nfs-storage
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm pull nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --version 4.0.18
tar -xzf nfs-subdir-external-provisioner-4.0.18.tgz
cp nfs-subdir-external-provisioner/values.yaml nfs-subdir.yaml
cat <<EOF > nfs-subdir.yaml
nfs:
  server: 192.168.23.114
  path: /home/nguyenlee24/data/volumes
  mountOptions:
  volumeName: nfs-subdir-external-provisioner-root
  reclaimPolicy: Retain
EOF
helm install nfs-storage -f nfs-subdir.yaml nfs-subdir-external-provisioner
kubectl get pvc
