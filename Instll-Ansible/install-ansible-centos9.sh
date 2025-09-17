#!/bin/bash

# Cài đặt Ansible trên CentOS 9 bằng pip

set -e

echo "=== Bắt đầu cài đặt Ansible ==="

# 1. Cập nhật hệ thống
echo "[+] Cập nhật hệ thống..."
sudo dnf update -y

# 2. Cài Python 3 và pip
echo "[+] Cài Python3 và pip..."
sudo dnf install -y python3 python3-pip

# 3. Kiểm tra pip
echo "[+] Kiểm tra pip..."
python3 -m pip -V

# 4. Cập nhật pip
echo "[+] Cập nhật pip..."
python3 -m pip install --upgrade pip --user

# 5. Cài Ansible (bản đầy đủ)
echo "[+] Cài Ansible..."
python3 -m pip install --user ansible

# 6. Kiểm tra phiên bản Ansible
echo "[+] Kiểm tra phiên bản Ansible..."
~/.local/bin/ansible --version

# 7. Thêm ~/.local/bin vào PATH nếu cần
if ! echo $PATH | grep -q "$HOME/.local/bin"; then
  echo "[+] Thêm ~/.local/bin vào PATH..."
  echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
  source ~/.bashrc
fi

echo "=== Cài đặt hoàn tất! ==="
echo "Bạn có thể chạy lệnh: ansible --version"
