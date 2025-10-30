

## 1. Cấu hình cơ bản

### 1.1 Đặt hostname và IP tĩnh

**Trên Server A (192.168.23.11)**:
```bash
sudo hostnamectl set-hostname server-a
sudo bash -c 'cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    ens33:
      addresses:
        - 192.168.23.11/24
      gateway4: 192.168.23.2
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF'
sudo netplan apply
```

**Trên Server B (192.168.23.12)**:
```bash
sudo hostnamectl set-hostname server-b
sudo bash -c 'cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    ens33:
      addresses:
        - 192.168.23.12/24
      gateway4: 192.168.23.2
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF'
sudo netplan apply
```

**Trên Server C (192.168.23.13)**:
```bash
sudo hostnamectl set-hostname server-c
sudo bash -c 'cat << EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    ens33:
      addresses:
        - 192.168.23.13/24
      gateway4: 192.168.23.2
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF'
sudo netplan apply
```

### 1.2 Tạo user và phân quyền

**Trên tất cả server**:
```bash
sudo useradd -m -s /bin/bash --ingroup operator operator
sudo useradd -m -s /bin/bash monitor
sudo useradd -m -s /bin/bash admin
sudo usermod -aG sudo admin
sudo bash -c 'echo "operator ALL=(ALL) /bin/systemctl restart nginx" >> /etc/sudoers.d/operator'
sudo bash -c 'echo "monitor ALL=(ALL) NOPASSWD: /bin/cat /var/log/nginx/*.log" >> /etc/sudoers.d/monitor'
sudo chmod 440 /etc/sudoers.d/*
```

**Giải thích**:  
- `operator`: Có quyền restart Nginx.  
- `monitor`: Chỉ đọc log Nginx.  
- `admin`: Full quyền sudo.

## 2. Quản lý dịch vụ và tiến trình

### 2.1 Cài đặt Nginx và cấu hình

**Trên Server B**:
```bash
sudo apt update
sudo apt install -y nginx
sudo mkdir -p /var/www/secure
sudo bash -c 'echo "<h1>Secure Area</h1>" > /var/www/secure/index.html'
sudo apt install -y apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd user1
sudo bash -c 'cat << EOF > /etc/nginx/sites-available/secure
server {
    listen 80;
    server_name serverB 192.168.23.12;
    root /var/www/secure;
    access_log /var/log/nginx/access.log;
    location /secure {
        auth_basic "Restricted Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
}
EOF'
sudo ln -s /etc/nginx/sites-available/secure /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx
```

### 2.2 Tạo custom systemd service

**Trên Server A** (backup service):
```bash
sudo bash -c 'cat << EOF > /usr/local/bin/backup.sh
#!/bin/bash
tar -czf /backup/etc-$(date +%F).tar.gz /etc
EOF'
sudo chmod +x /usr/local/bin/backup.sh
sudo bash -c 'cat << EOF > /etc/systemd/system/backup.service
[Unit]
Description=Daily Backup Service
[Service]
ExecStart=/usr/local/bin/backup.sh
[Install]
WantedBy=multi-user.target
EOF'
sudo systemctl enable backup.service
```

## 3. Sử dụng crontab và systemctl

### 3.1 Script backup hàng ngày

**Trên Server A**:
```bash
sudo mkdir -p /backup
sudo crontab -e
# Thêm dòng sau vào crontab
0 2 * * * /usr/local/bin/backup.sh
```

**Giải thích**: Script backup `/etc` vào `/backup/etc-YYYY-MM-DD.tar.gz` lúc 2h sáng mỗi ngày.

### 3.2 Đảm bảo service chạy nền

Đã cấu hình systemd service ở bước 2.2, đảm bảo backup chạy tự động khi cần.

## 4. Logging & Monitoring

### 4.1 Cấu hình rsyslog

**Trên Server B** (gửi log):
```bash
sudo bash -c 'echo "*.* @192.168.23.11:514" >> /etc/rsyslog.conf'
sudo systemctl restart rsyslog
```

**Trên Server A** (nhận log):
```bash
sudo bash -c 'cat << EOF >> /etc/rsyslog.conf
*.* /var/log/remote.log
EOF'
sudo systemctl restart rsyslog
sudo ufw allow 514/udp
```

### 4.2 Cài fail2ban trên Server B

```bash
sudo apt install -y fail2ban
sudo bash -c 'cat << EOF > /etc/fail2ban/jail.d/nginx-auth.conf
[nginx-auth]
enabled = true
port = 80
filter = nginx-auth
logpath = /var/log/nginx/access.log
maxretry = 3
findtime = 600
bantime = 3600
action = iptables-multiport[name=nginx-auth, port="http,https"]
EOF'
sudo bash -c 'cat << EOF > /etc/fail2ban/filter.d/nginx-auth.conf
[Definition]
failregex = ^<HOST> - \S+ \[.*\] "GET /secure.* 401.*$
ignoreregex =
EOF'
sudo systemctl restart fail2ban
```

**Giải thích**: Chặn IP sau 3 lần truy cập sai vào `/secure` trong 10 phút (600 giây), cấm trong 1 giờ (3600 giây).

## 5. Sử dụng SSH key và Jump Host

### 5.1 Tạo và copy SSH key
## Phân tích
- **Yêu cầu thay đổi user**: Thay `operator` bằng `nguyenlee24` để quản lý SSH key và truy cập qua Jump Host.  
- **Câu hỏi về cổng 2222**: Cổng 2222 được chọn để tránh xung đột với cổng 22 mặc định, thường bị nhắm mục tiêu bởi các cuộc tấn công brute-force.

## Các bước triển khai

### Bước 1: Cập nhật user nguyenlee24
#### Trên Server C
Tạo và sao chép SSH key cho user `nguyenlee24`:
```bash
sudo -u nguyenlee24 ssh-keygen -t rsa -b 4096 -f /home/nguyenlee24/.ssh/id_rsa
sudo -u nguyenlee24 ssh-copy-id -i /home/nguyenlee24/.ssh/id_rsa.pub nguyenlee24@192.168.23.11
sudo -u nguyenlee24 ssh-copy-id -i /home/nguyenlee24/.ssh/id_rsa.pub nguyenlee24@192.168.23.12
```
**Kỳ vọng**: Key được tạo và sao chép thành công đến Server A và B.

#### Trên Server A và B
thêm 

AllowUsers root@192.168.23.13
/etc/ssh/sshd_config
Cập nhật `/etc/ssh/sshd_config` để cho phép user `nguyenlee24` thay cho `operator`:
```bash
sudo sed -i '/Match Address 192.168.23.13/{n;s/operator/nguyenlee24/}' /etc/ssh/sshd_config
sudo systemctl restart sshd
```
Kiểm tra:
```bash
sudo cat /etc/ssh/sshd_config | grep -A 1 "Match Address 192.168.23.13"
```
**Kỳ vọng**: Hiển thị `AllowUsers nguyenlee24`.

#### Trên Server C
Đảm bảo cổng 2222 và cấu hình SSH:
```bash
sudo ufw allow 2222
sudo bash -c 'cat << EOF >> /etc/ssh/sshd_config
Port 2222
PermitRootLogin no
PasswordAuthentication no
EOF'
sudo systemctl restart sshd
```
Kiểm tra:
```bash
sudo ufw status
sudo netstat -tuln | grep 2222
```
**Kỳ vọng**: Cổng 2222 được phép và lắng nghe.

### Bước 2: Cấu hình tường lửa
#### Trên Server A và B
Cập nhật `ufw` để chỉ cho phép SSH từ Server C:
```bash
sudo ufw allow from 192.168.23.13 to any port 22 proto tcp
sudo ufw enable
```
Kiểm tra:
```bash
sudo ufw status
```
**Kỳ vọng**: Chỉ cho phép SSH từ `192.168.23.13` trên cổng 22.

### Bước 3: Kiểm tra truy cập
Từ máy local, truy cập qua Jump Host:
```bash
ssh -J nguyenlee24@192.168.23.13:2222 nguyenlee24@192.168.23.11
ssh -J nguyenlee24@192.168.23.13:2222 nguyenlee24@192.168.23.12
```
**Kỳ vọng**: Kết nối thành công mà không cần mật khẩu.

## Giải thích tại sao dùng cổng 2222 thay vì 22
- **Lý do an ninh**: Cổng 22 là cổng SSH mặc định, thường bị quét và tấn công brute-force bởi botnet. Sử dụng cổng 2222 (hoặc cổng tùy chỉnh khác) làm giảm khả năng bị nhắm mục tiêu, đặc biệt với Jump Host (Server C) là điểm truy cập duy nhất.  
- **Tính linh hoạt**: Trong môi trường lab, cổng 2222 được chọn để minh họa cấu hình tùy chỉnh, giúp bạn làm quen với việc thay đổi cổng SSH.  
- **Không xung đột**: Server A và B vẫn dùng cổng 22 để nhận kết nối từ Server C, trong khi Server C dùng 2222 để nhận từ máy local, tránh xung đột trong cấu hình mạng nội bộ.

## Kết luận
- User `nguyenlee24` đã được cấu hình để thay thế `operator` trong SSH Jump Host.  
- Cổng 2222 được chọn để tăng cường an ninh và tránh xung đột với cổng 22 mặc định.  
- Nếu gặp lỗi (ví dụ: không kết nối được), kiểm tra log `/var/log/auth.log` trên Server C, A, hoặc B, hoặc cung cấp kết quả lệnh `ssh -v`.

## 6. Giám sát tài nguyên (Lab 6)

### Yêu cầu
- Cài đặt `htop`, `vmstat`, `sysstat` để giám sát CPU, RAM.
- Sử dụng `monitor.py` để ghi log CPU, RAM, Disk mỗi 5 giây trong 60 giây, vẽ biểu đồ, lưu vào `/var/log/monitor_logs/YYYY-MM-DD/sys_usage_chart_YYYYMMDD_HHMMSS.png`.
- Sử dụng `sys_usage_monitor.py` để ghi log mỗi phút trong 1 giờ, lưu vào `/var/log/monitor_logs/YYYY-MM-DD/sys_usage_YYYY-MM-DD.csv`, và vẽ biểu đồ.
- Tự động hóa với systemd timer chạy mỗi 2 giờ cho `monitor.py` và mỗi giờ cho `sys_usage_monitor.py`.

### Các bước triển khai

#### Bước 1: Cài đặt công cụ giám sát

**Trên Server B**:
```bash
sudo apt update
sudo apt install -y htop sysstat
```

**Kiểm tra**:
```bash
htop
vmstat 1
sar 1
```

**Kỳ vọng**: 
- `htop`: Hiển thị giao diện giám sát CPU, RAM, tiến trình.
- `vmstat 1`: Cập nhật tài nguyên mỗi giây.
- `sar 1`: Báo cáo thống kê hệ thống.

#### Bước 2: Triển khai script giám sát

**Cài đặt thư viện**:
```bash
sudo apt install -y python3-psutil python3-matplotlib
```

**Script `monitor.py`**:
```bash
sudo bash -c 'cat << EOF > /usr/local/bin/monitor.py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import psutil
import time
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from datetime import datetime

# Config
duration = 60  # 60 giây
interval = 5   # Mỗi 5 giây
log_dir = "/var/log/monitor_logs"
os.makedirs(log_dir, exist_ok=True)

def monitor_system_usage():
    date_str = datetime.now().strftime("%Y-%m-%d")
    log_file = os.path.join(log_dir, date_str, f"sys_usage_{date_str}.csv")
    img_dir = os.path.join(log_dir, date_str)
    os.makedirs(img_dir, exist_ok=True)
    
    timestamps, cpus, rams, disks = [], [], [], []
    with open(log_file, "a", encoding="utf-8") as f:
        if os.path.getsize(log_file) == 0:
            f.write("timestamp,cpu,ram,disk\n")
        start_time = time.time()
        while time.time() - start_time < duration:
            cpu = psutil.cpu_percent(interval=1)
            ram = psutil.virtual_memory().percent
            disk = psutil.disk_usage("/").percent
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            f.write(f"{timestamp},{cpu},{ram},{disk}\n")
            timestamps.append(timestamp[11:])
            cpus.append(float(cpu))
            rams.append(float(ram))
            disks.append(float(disk))
            time.sleep(interval)

    # Vẽ biểu đồ
    plt.figure(figsize=(10, 6))
    plt.plot(timestamps, cpus, label="CPU (%)", color="blue")
    plt.plot(timestamps, rams, label="RAM (%)", color="red")
    plt.plot(timestamps, disks, label="Disk (%)", color="green")
    plt.xlabel("Thời gian")
    plt.ylabel("Tỷ lệ sử dụng (%)")
    plt.title("Tài nguyên hệ thống trên Server B")
    plt.xticks(rotation=45)
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    
    img_path = os.path.join(img_dir, f"sys_usage_chart_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png")
    plt.savefig(img_path)
    plt.close()
    print(f"[{date_str}] Lưu biểu đồ: {img_path}")

if __name__ == "__main__":
    monitor_system_usage()
EOF'
sudo chmod +x /usr/local/bin/monitor.py
```

**Script `sys_usage_monitor.py`**:
```bash
sudo bash -c 'cat << EOF > /usr/local/bin/sys_usage_monitor.py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import psutil
import time
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from datetime import datetime

# Config
log_dir = "/var/log/monitor_logs"
duration = 3600  # 1 giờ
interval = 60    # Mỗi 60 giây

def log_system_usage():
    date_str = datetime.now().strftime("%Y-%m-%d")
    log_file = os.path.join(log_dir, date_str, f"sys_usage_{date_str}.csv")
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    with open(log_file, "a", encoding="utf-8") as f:
        if os.path.getsize(log_file) == 0:
            f.write("timestamp,cpu,ram,disk\n")
        start_time = time.time()
        while time.time() - start_time < duration:
            cpu = psutil.cpu_percent(interval=1)
            ram = psutil.virtual_memory().percent
            disk = psutil.disk_usage("/").percent
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            f.write(f"{timestamp},{cpu},{ram},{disk}\n")
            time.sleep(interval)

def plot_usage_graph():
    date_str = datetime.now().strftime("%Y-%m-%d")
    log_file = os.path.join(log_dir, date_str, f"sys_usage_{date_str}.csv")
    if not os.path.exists(log_file):
        print(f"Lỗi: Không tìm thấy file log {log_file}")
        return
    timestamps, cpus, rams, disks = [], [], [], []
    with open(log_file) as f:
        next(f)  # Bỏ header
        for line in f:
            ts, cpu, ram, disk = line.strip().split(",")
            timestamps.append(ts[11:])
            cpus.append(float(cpu))
            rams.append(float(ram))
            disks.append(float(disk))

    plt.figure(figsize=(10, 6))
    plt.plot(timestamps, cpus, label="CPU (%)", color="blue")
    plt.plot(timestamps, rams, label="RAM (%)", color="red")
    plt.plot(timestamps, disks, label="Disk (%)", color="green")
    plt.xlabel("Thời gian")
    plt.ylabel("Tỷ lệ sử dụng (%)")
    plt.title("Tài nguyên hệ thống trên Server B")
    plt.xticks(rotation=45)
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    
    img_path = os.path.join(log_dir, date_str, f"sys_usage_chart_{date_str}.png")
    plt.savefig(img_path)
    plt.close()
    print(f"[{date_str}] Lưu biểu đồ: {img_path}")

if __name__ == "__main__":
    log_system_usage()
    plot_usage_graph()
EOF'
sudo chmod +x /usr/local/bin/sys_usage_monitor.py
```

**Cấu hình quyền thư mục**:
```bash
sudo mkdir -p /var/log/monitor_logs
sudo chown -R monitor:monitor /var/log/monitor_logs
sudo chmod -R 755 /var/log/monitor_logs
```

**Chạy thử script**:
```bash
sudo -u monitor python3 /usr/local/bin/monitor.py
sudo -u monitor python3 /usr/local/bin/sys_usage_monitor.py
```

**Kỳ vọng**: Script chạy không lỗi, tạo file CSV và biểu đồ tại `/var/log/monitor_logs/YYYY-MM-DD/`.

#### Bước 3: Tạo systemd service và timer

**Service `monitor.service`**:
```bash
sudo bash -c 'cat << EOF > /etc/systemd/system/monitor.service
[Unit]
Description=Giám sát tài nguyên hệ thống
After=network.target

[Service]
User=monitor
ExecStart=/usr/bin/python3 /usr/local/bin/monitor.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF'
```

**Timer `monitor.timer`**:
```bash
sudo bash -c 'cat << EOF > /etc/systemd/system/monitor.timer
[Unit]
Description=Chạy dịch vụ giám sát mỗi 2 giờ

[Timer]
OnCalendar=0/2:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF'
```

**Service `sys-usage-monitor.service`**:
```bash
sudo bash -c 'cat << EOF > /etc/systemd/system/sys-usage-monitor.service
[Unit]
Description=Giám sát tài nguyên hệ thống hàng giờ
After=network.target

[Service]
User=monitor
ExecStart=/usr/bin/python3 /usr/local/bin/sys_usage_monitor.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF'
```

**Timer `sys-usage-monitor.timer`**:
```bash
sudo bash -c 'cat << EOF > /etc/systemd/system/sys-usage-monitor.timer
[Unit]
Description=Chạy dịch vụ giám sát mỗi giờ

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF'
```

**Kích hoạt và khởi động**:
```bash
sudo systemctl daemon-reload
sudo systemctl enable monitor.timer
sudo systemctl start monitor.timer
sudo systemctl enable sys-usage-monitor.timer
sudo systemctl start sys-usage-monitor.timer
```

**Kiểm tra trạng thái**:
```bash
sudo systemctl status monitor.timer
sudo systemctl status sys-usage-monitor.timer
sudo systemctl list-timers
```

**Kỳ vọng**:
- `monitor.timer` chạy mỗi 2 giờ, kích hoạt `monitor.service`.
- `sys-usage-monitor.timer` chạy mỗi giờ, kích hoạt `sys-usage-monitor.service`.

#### Bước 4: Kiểm tra đầu ra

```bash
ls -l /var/log/monitor_logs/$(date +%Y-%m-%d)
sudo -u monitor cat /var/log/monitor_logs/$(date +%Y-%m-%d)/sys_usage_$(date +%Y-%m-%d).csv
```

**Kỳ vọng**:
- File CSV `/var/log/monitor_logs/YYYY-MM-DD/sys_usage_YYYY-MM-DD.csv` chứa các dòng `timestamp,cpu,ram,disk`.
- File `sys_usage_chart_YYYYMMDD_HHMMSS.png` và `sys_usage_chart_YYYY-MM-DD.png` tồn tại.

#### Bước 5: Tự động hóa với crontab (dự phòng)

```bash
sudo crontab -u monitor -e
# Thêm dòng:
0 * * * * /usr/bin/python3 /usr/local/bin/sys_usage_monitor.py
```

**Kỳ vọng**: Script chạy mỗi giờ, tạo log và biểu đồ.

## 7. Cấu hình tường lửa (Lab 7)

### Yêu cầu
- Chỉ cho phép SSH từ Jump Host (Server C: 192.168.23.13).
- Chặn ping (ICMP) từ bên ngoài.

### Các bước triển khai

#### Trên Server A và B

**Cấu hình `ufw`**:
```bash
sudo ufw reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.23.13 to any port 22 proto tcp
sudo ufw allow 80/tcp
sudo ufw allow 514/udp
sudo ufw deny proto icmp
sudo ufw enable
```

**Kiểm tra**:
```bash
sudo ufw status
```

**Kỳ vọng**:
- Cho phép SSH từ `192.168.23.13` trên cổng 22.
- Cho phép cổng 80 (Server B), 514/UDP (Server A).
- Chặn ICMP.

#### Trên Server C

**Cấu hình `ufw`**:
```bash
sudo ufw reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp
sudo ufw enable
```

**Kiểm tra**:
```bash
sudo ufw status
```

**Kỳ vọng**: Cổng 2222 được phép.

#### Kiểm tra SSH qua Jump Host

Từ máy local:
```bash
ssh -J operator@192.168.23.13:2222 operator@192.168.23.12
```

**Kỳ vọng**: Kết nối thành công.

**Kiểm tra ping**:
```bash
ping 192.168.23.12
```

**Kỳ vọng**: Bị chặn (timeout).

## 8. Repository nội bộ (Lab 9)

### Yêu cầu
- Server A làm repository nội bộ Ubuntu với `apt-mirror`.
- Server B và C sử dụng repo nội bộ từ Server A.

### Các bước triển khai

#### Trên Server A

**Cài đặt và cấu hình `apt-mirror`**:
```bash
sudo apt install -y apt-mirror apache2
sudo bash -c 'cat << EOF > /etc/apt/mirror.list
set base_path /var/spool/apt-mirror
set mirror_path \$base_path/mirror
set skel_path \$base_path/skel
set var_path \$base_path/var
set defaultarch amd64
deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-security main restricted universe multiverse
EOF'
sudo apt-mirror
```

**Cấu hình Apache**:
```bash
sudo bash -c 'cat << EOF > /etc/apache2/sites-available/apt-mirror.conf
<VirtualHost *:80>
    ServerName 192.168.23.11
    DocumentRoot /var/spool/apt-mirror/mirror/archive.ubuntu.com/ubuntu
    <Directory /var/spool/apt-mirror/mirror/archive.ubuntu.com/ubuntu>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF'
sudo a2ensite apt-mirror.conf
sudo systemctl reload apache2
sudo ufw allow 80/tcp
```

**Kỳ vọng**: Repo tại `/var/spool/apt-mirror/mirror/archive.ubuntu.com/ubuntu`, truy cập qua `http://192.168.23.11`.

#### Trên Server B và C

**Lưu ý**: Hãy backup file `/etc/apt/sources.list` trước khi thay đổi.

**Cấu hình sử dụng repo nội bộ**:
```bash
sudo bash -c 'cat << EOF > /etc/apt/sources.list
deb http://192.168.23.11 jammy main restricted universe multiverse
deb http://192.168.23.11 jammy-updates main restricted universe multiverse
deb http://192.168.23.11 jammy-security main restricted universe multiverse
EOF'
sudo apt update
```

**Kiểm tra**:
```bash
sudo apt install -y htop
```

**Kỳ vọng**: Gói được cài từ repo nội bộ.

## Kết luận
- **Cấu hình cơ bản**: Đặt hostname, IP tĩnh, tạo user với phân quyền phù hợp.
- **Quản lý dịch vụ**: Cài Nginx trên Server B, tạo backup service trên Server A.
- **Logging & Monitoring**: Cấu hình rsyslog, fail2ban, và giám sát tài nguyên.
- **SSH và Jump Host**: Server C làm Jump Host với SSH key, tăng cường bảo mật.
- **Lab 6**: Script `monitor.py` và `sys_usage_monitor.py` ghi log và vẽ biểu đồ, chạy tự động qua systemd timer.
- **Lab 7**: Tường lửa chỉ cho phép SSH từ Server C, chặn ICMP.
- **Lab 9**: Server A làm repo nội bộ, Server B và C sử dụng thành công.

**Xử lý lỗi**:
- Kiểm tra log: `journalctl -u monitor.timer`, `journalctl -u sys-usage-monitor.timer`, `/var/log/fail2ban.log`.
- Nếu cần hỗ trợ thêm, cung cấp kết quả lệnh hoặc log liên quan.


# Hướng dẫn cấu hình LVM trên Server B

Dưới đây là các bước để cấu hình LVM trên Server B (Ubuntu 22.04) theo yêu cầu, bao gồm tạo ổ đĩa, Volume Group, Logical Volume, định dạng, mount, liên kết log Nginx, và mở rộng LVM.

## Bước 1: Tạo ổ đĩa 10GB trong VMware Workstation 10
1. Mở VMware Workstation 10, chọn máy ảo Server B.
2. Vào **Edit virtual machine settings** > **Add** > **Hard Disk** > **SCSI** > **Create a new virtual disk**.
3. Đặt dung lượng **10GB**, chọn **Store virtual disk as a single file** để đơn giản hóa quản lý.
4. Hoàn tất và khởi động lại máy ảo nếu cần.

**Kiểm tra**:
```bash
lsblk
```
**Kỳ vọng**: Thấy ổ đĩa mới (ví dụ: `/dev/sdb`) với dung lượng ~10GB.

## Bước 2: Cài đặt công cụ LVM
```bash
sudo apt update
sudo apt install -y lvm2
```

**Kiểm tra**:
```bash
lvm version
```
**Kỳ vọng**: Hiển thị phiên bản LVM2 được cài đặt.

## Bước 3: Tạo Physical Volume (PV)
```bash
sudo pvcreate /dev/sdb
```

**Kiểm tra**:
```bash
sudo pvs
```
**Kỳ vọng**: `/dev/sdb` được liệt kê là Physical Volume.

## Bước 4: Tạo Volume Group (vg_log)
```bash
sudo vgcreate vg_log /dev/sdb
```

**Kiểm tra**:
```bash
sudo vgs
```
**Kỳ vọng**: Volume Group `vg_log` xuất hiện với dung lượng ~10GB.

## Bước 5: Tạo Logical Volume (lv_nginx)
```bash
sudo lvcreate -L 2G -n lv_nginx vg_log
```

**Kiểm tra**:
```bash
sudo lvs
```
**Kỳ vọng**: Logical Volume `lv_nginx` được tạo với dung lượng 2GB.

## Bước 6: Định dạng và mount Logical Volume
1. **Định dạng ext4**:
```bash
sudo mkfs.ext4 /dev/vg_log/lv_nginx
```

2. **Tạo thư mục mount point**:
```bash
sudo mkdir -p /var/log/nginx-data
```

3. **Mount tạm thời**:
```bash
sudo mount /dev/vg_log/lv_nginx /var/log/nginx-data
```

**Kiểm tra**:
```bash
df -h /var/log/nginx-data
```
**Kỳ vọng**: Thấy `/dev/mapper/vg_log-lv_nginx` được mount với dung lượng ~2GB.

## Bước 7: Cấu hình tự động mount trong /etc/fstab
1. Lấy UUID của Logical Volume:
```bash
sudo blkid /dev/vg_log/lv_nginx
```
Sao chép UUID từ output (ví dụ: `UUID="abcd1234-..."`).

2. Chỉnh sửa `/etc/fstab`:
```bash
sudo bash -c 'echo "UUID=<UUID> /var/log/nginx-data ext4 defaults 0 2" >> /etc/fstab'
```
Thay `<UUID>` bằng UUID thực tế từ lệnh `blkid`.

3. Kiểm tra cấu hình:
```bash
sudo mount -a
```
**Kỳ vọng**: Không có lỗi, `/var/log/nginx-data` được mount.

## Bước 8: Cấu hình Nginx để ghi log vào /var/log/nginx-data
1. Sửa file cấu hình Nginx `/etc/nginx/sites-available/secure`:
```bash
sudo bash -c 'cat << EOF > /etc/nginx/sites-available/secure
server {
    listen 80;
    server_name serverB 192.168.23.12;
    root /var/www/secure;
    access_log /var/log/nginx-data/access.log;
    error_log /var/log/nginx-data/error.log;
    location /secure {
        auth_basic "Restricted Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
}
EOF'
```

2. Kiểm tra và khởi động lại Nginx:
```bash
sudo nginx -t
sudo systemctl restart nginx
```

3. Tạo symlink (tùy chọn để tương thích với cấu hình cũ):
```bash
sudo ln -sf /var/log/nginx-data/access.log /var/log/nginx/access.log
sudo ln -sf /var/log/nginx-data/error.log /var/log/nginx/error.log
```

**Kiểm tra**:
```bash
ls -l /var/log/nginx-data
sudo cat /var/log/nginx-data/access.log
```
**Kỳ vọng**: File `access.log` và `error.log` được tạo trong `/var/log/nginx-data`.

## Bước 9: (Tùy chọn) Mở rộng lv_nginx thêm 1GB
1. Mở rộng Logical Volume:
```bash
sudo lvextend -L +1G /dev/vg_log/lv_nginx
```

2. Resize filesystem online:
```bash
sudo resize2fs /dev/vg_log/lv_nginx
```

**Kiểm tra**:
```bash
sudo lvs
df -h /var/log/nginx-data
```
**Kỳ vọng**: `lv_nginx` có dung lượng ~3GB, filesystem được mở rộng mà không mất dữ liệu.

## Kết luận
- Đã cấu hình LVM trên Server B với Volume Group `vg_log` và Logical Volume `lv_nginx` (2GB, mở rộng thêm 1GB).
- Log Nginx được ghi vào `/var/log/nginx-data` thông qua cấu hình `access_log` và `error_log`.
- Tự động mount được thiết lập qua `/etc/fstab`.
- Hệ thống lưu trữ log ổn định, dễ mở rộng với LVM.

**Xử lý lỗi**:
- Nếu mount thất bại: Kiểm tra UUID trong `/etc/fstab` và chạy `sudo mount -a`.
- Nếu Nginx không ghi log: Kiểm tra quyền thư mục `/var/log/nginx-data` (`sudo chown -R www-data:www-data /var/log/nginx-data`).
- Xem log hệ thống: `journalctl -u nginx` hoặc `dmesg`.