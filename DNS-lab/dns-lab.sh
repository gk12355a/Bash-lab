#!/bin/bash
#####################################################################
# Tên: Lab DNS Server & Client
# Người thực hiện: Đỗ Trí Kiên
# Ngày: 18/09/2025
#
# Mô hình lab:
#   - DNS Server: 192.168.23.132 (hostname: DNS-server, cài BIND9)
#   - Client:     192.168.23.122 (hostname: devlopment, dùng để test)
#
# Domain nội bộ: blogd.lab
# Dịch vụ: BIND9 làm DNS Master cho domain blogd.lab
#
# Chức năng:
#   - Cấu hình forward lookup (www.blogd.lab -> 192.168.23.132)
#   - Cấu hình reverse lookup (192.168.23.132 -> server1.blogd.lab)
#   - Cấu hình client sử dụng DNS server
#####################################################################
set -e

echo "=== CÀI ĐẶT VÀ CẤU HÌNH DNS SERVER (BIND9) ==="

if [ "$(hostname)" = "DNS-server" ]; then
    echo "[SERVER] Cài đặt BIND9..."
    apt update -y
    apt install -y bind9 bind9utils bind9-doc dnsutils

    echo "[SERVER] Tạo file zone cho blogd.lab..."
    cat > /etc/bind/db.blogd.lab <<EOF
\$TTL    86400
@       IN      SOA     ns1.blogd.lab. root.blogd.lab. (
                        2025091801 ; Serial
                        3600       ; Refresh
                        1800       ; Retry
                        604800     ; Expire
                        86400 )    ; Minimum TTL

        IN      NS      ns1.blogd.lab.

ns1     IN      A       192.168.23.132
server1 IN      A       192.168.23.132
www     IN      CNAME   server1
EOF

    echo "[SERVER] Tạo file reverse zone..."
    cat > /etc/bind/db.192.168.23 <<EOF
\$TTL    86400
@       IN      SOA     ns1.blogd.lab. root.blogd.lab. (
                        2025091801
                        3600
                        1800
                        604800
                        86400 )

        IN      NS      ns1.blogd.lab.
132     IN      PTR     server1.blogd.lab.
EOF

    echo "[SERVER] Cập nhật named.conf.local..."
    cat > /etc/bind/named.conf.local <<EOF
zone "blogd.lab" {
    type master;
    file "/etc/bind/db.blogd.lab";
};

zone "23.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.23";
};
EOF

    echo "[SERVER] Kiểm tra cấu hình..."
    named-checkconf
    named-checkzone blogd.lab /etc/bind/db.blogd.lab
    named-checkzone 23.168.192.in-addr.arpa /etc/bind/db.192.168.23

    echo "[SERVER] Restart dịch vụ BIND9..."
    systemctl restart named
    systemctl enable named

    echo "[SERVER] Test dig tại server..."
    dig @192.168.23.132 www.blogd.lab
    dig -x 192.168.23.132 @192.168.23.132
fi

echo "=== CẤU HÌNH CLIENT ==="
if [ "$(hostname)" = "devlopment" ]; then
    echo "[CLIENT] Chỉnh resolv.conf..."
    bash -c 'echo "nameserver 192.168.23.132" > /etc/resolv.conf'

    echo "[CLIENT] Cập nhật netplan để cố định DNS..."
    cat > /etc/netplan/00-installer-config.yaml <<EOF
network:
  ethernets:
    ens33:
      dhcp4: no
      addresses: [192.168.23.122/24]
      gateway4: 192.168.23.2
      nameservers:
        addresses: [192.168.23.132,8.8.8.8,8.8.4.4]
  version: 2
EOF

    netplan apply

    echo "[CLIENT] Test nslookup..."
    nslookup www.blogd.lab
    nslookup server1.blogd.lab
    dig www.blogd.lab
fi

echo "=== HOÀN THÀNH LAB DNS ==="
