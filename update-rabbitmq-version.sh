#!/bin/bash

echo "🚨 Đang gỡ RabbitMQ cũ..."
sudo systemctl stop rabbitmq-server
sudo yum remove -y rabbitmq-server
sudo rm -rf /var/lib/rabbitmq/
sudo rm -f /etc/yum.repos.d/centos-rabbitmq-38.repo

echo "📦 Thêm repo RabbitMQ mới..."
sudo tee /etc/yum.repos.d/rabbitmq.repo <<EOF
[rabbitmq-server]
name=RabbitMQ Server
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/9/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey
EOF

echo "📥 Đang cài RabbitMQ phiên bản mới nhất..."
sudo yum install -y rabbitmq-server

echo "🚀 Khởi động RabbitMQ..."
sudo systemctl enable --now rabbitmq-server

echo "👤 Tạo user 'test' và cấp quyền..."
sudo rabbitmqctl add_user test test
sudo rabbitmqctl set_permissions -p / test ".*" ".*" ".*"

echo "✅ Kiểm tra version:"
rabbitmqctl status | grep RabbitMQ
