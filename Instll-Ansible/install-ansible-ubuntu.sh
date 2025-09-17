#!/bin/bash

# Cài đặt Ansible trên Ubuntu bằng pip

set -e

echo "=== Bắt đầu cài đặt Ansible trên Ubuntu ==="

# 1. Cập nhật hệ thống
echo "[+] Cập nhật hệ thống..."
sudo apt update && sudo apt upgrade -y

# 2. Cài Python3 và pip
echo "[+] Cài đặt Python3 và pip..."
sudo apt install -y python3 python3-pip python3-venv

# 3. Kiểm tra pip
echo "[+] Kiểm tra pip..."
python3 -m pip -V

# 4. Cập nhật pip mới nhất
echo "[+] Cập nhật pip..."
python3 -m pip install --upgrade pip --user

# 5. Cài đặt Ansible đầy đủ bằng pip
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
echo "Bạn có thể chạy: ansible --version"
