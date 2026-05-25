#!/bin/bash
set -e

MASTER_IP="192.168.23.12"

echo "[STEP] Update hosts"
sudo tee -a /etc/hosts > /dev/null <<EOF
192.168.23.11 alf
192.168.23.12 DB-master
192.168.23.13 DB-slave
EOF

echo "[STEP] Install MariaDB"
sudo apt update
sudo apt install -y mariadb-server
sudo systemctl enable --now mariadb

echo "[STEP] Configure MariaDB Slave"
sudo sed -i '/^\[mysqld\]/a server-id = 2\nrelay-log = /var/log/mysql/mysql-relay-bin.log\nlog_bin = /var/log/mysql/mysql-bin.log\nread_only = 1\nbind-address = 0.0.0.0' /etc/mysql/mariadb.conf.d/50-server.cnf || true
sudo systemctl restart mariadb

echo ">>> DONE."
echo ">>> Bây giờ vào MySQL và chạy lệnh sau (thay FILE & POS bằng từ master):"
cat <<EOF
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO
  MASTER_HOST='${MASTER_IP}',
  MASTER_USER='replica_user',
  MASTER_PASSWORD='Tech@1604',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=123;
START SLAVE;
SHOW SLAVE STATUS\G
EOF
