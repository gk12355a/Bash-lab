#!/bin/bash
sudo apt update
sudo apt install -y nfs-kernel-server firewalld
mkdir -p /home/nguyenlee24/data/volumes
sudo chown 1000:1000 /home/nguyenlee24/data
sudo chmod 777 /home/nguyenlee24/data/volumes
echo "/home/nguyenlee24/data/volumes *(rw,no_root_squash,no_subtree_check)" | sudo tee /etc/exports
sudo systemctl restart nfs-kernel-server.service
firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
firewall-cmd --reload
echo "NFS server đã được cài đặt và cấu hình thành công!"