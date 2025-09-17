#!/bin/bash

echo "Chọn hệ điều hành để cài đặt:"
echo "1. CentOS Stream 9"
echo "2. Ubuntu 22.04"
read -p "Nhập lựa chọn (1 hoặc 2): " choice

case $choice in
  1)
    echo "Cài đặt CentOS Stream 9..."
    # Các lệnh cài đặt cho CentOS Stream 9
    sudo dnf install -y epel-release
    sudo dnf install -y git java-21-openjdk net-tools
    sudo dnf config-manager --add-repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo dnf install -y jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
    ;;
  2)
    echo "Cài đặt Ubuntu 22.04..."
    # Các lệnh cài đặt cho Ubuntu 22.04
    sudo apt update
    sudo apt install -y fontconfig openjdk-21-jre git net-tools
    wget -q https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb https://pkg.jenkins.io/debian-stable jenkins" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
    ;;
  *)
    echo "Lựa chọn không hợp lệ! Vui lòng chọn 1 hoặc 2."
    exit 1
    ;;
esac

echo "Cài đặt hoàn tất! Kiểm tra trạng thái với: sudo systemctl status jenkins"