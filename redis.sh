#!/bin/bash

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
  echo "Vui lòng chạy script này với quyền root (sudo)."
  exit 1
fi

# Cài đặt EPEL repository (cần cho Redis)
echo "Cài đặt EPEL repository..."
dnf install -y epel-release

# Cài đặt Redis
echo "Cài đặt Redis..."
dnf install -y redis

# Sao lưu tệp cấu hình gốc
echo "Sao lưu tệp cấu hình Redis..."
cp /etc/redis/redis.conf /etc/redis/redis.conf.bak

# Cấu hình Redis để lắng nghe trên IP và port cụ thể
echo "Cấu hình Redis để lắng nghe trên 192.168.23.11:6379..."
sed -i 's/^bind 127.0.0.1 -::1/bind 192.168.23.11/' /etc/redis/redis.conf
sed -i 's/^port 6379/port 6379/' /etc/redis/redis.conf

# Vô hiệu hóa chế độ bảo vệ (nếu cần cho môi trường không chuẩn)
echo "Vô hiệu hóa protected-mode..."
sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf

# Đảm bảo không yêu cầu mật khẩu
echo "Đảm bảo không yêu cầu mật khẩu..."
sed -i 's/^# requirepass foobared/requirepass ""/' /etc/redis/redis.conf

# Cấu hình cơ sở dữ liệu mặc định (DB 0)
echo "Cấu hình cơ sở dữ liệu mặc định (DB 0)..."
sed -i 's/^databases 16/databases 1/' /etc/redis/redis.conf

# Khởi động và kích hoạt dịch vụ Redis
echo "Khởi động và kích hoạt Redis..."
systemctl start redis
systemctl enable redis

# Kiểm tra trạng thái Redis
echo "Kiểm tra trạng thái Redis..."
systemctl status redis --no-pager

# Kiểm tra kết nối Redis
echo "Kiểm tra kết nối Redis..."
redis-cli -h 192.168.23.11 -p 6379 ping
if [ $? -eq 0 ]; then
  echo "Redis đang chạy và phản hồi PONG."
else
  echo "Lỗi: Không thể kết nối tới Redis. Vui lòng kiểm tra nhật ký: journalctl -u redis"
  exit 1
fi

# Mở cổng 6379 trên tường lửa (nếu firewalld đang hoạt động)
if systemctl is-active firewalld >/dev/null; then
  echo "Mở cổng 6379 trên tường lửa..."
  firewall-cmd --permanent --add-port=6379/tcp
  firewall-cmd --reload
fi

echo "Cài đặt và cấu hình Redis hoàn tất!"