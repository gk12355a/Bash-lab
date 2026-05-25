#!/bin/bash
set -e
Tech@1604
DBNAME="mydb"
MHA_USER="replica_user"
MHA_PASS="Tech@1604"
APP_USER="app_user"
APP_PASS="Tech@1604"
# pass root = Tech@1604
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

echo "[STEP] Configure MariaDB Master"
sudo sed -i '/^\[mysqld\]/a server-id = 1\nlog_bin = /var/log/mysql/mysql-bin.log\nbinlog_format = ROW\nbind-address = 0.0.0.0\nbinlog_do_db = '"$DBNAME"'' /etc/mysql/mariadb.conf.d/50-server.cnf || true
sudo systemctl restart mariadb

echo "[STEP] Create DB and Users"
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${DBNAME};
USE ${DBNAME};
CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255));
INSERT INTO users (name) VALUES ('Test User') ON DUPLICATE KEY UPDATE name=name;

CREATE USER IF NOT EXISTS '${MHA_USER}'@'%' IDENTIFIED BY '${MHA_PASS}';
GRANT REPLICATION SLAVE ON *.* TO '${MHA_USER}'@'%';

CREATE USER IF NOT EXISTS '${APP_USER}'@'%' IDENTIFIED BY '${APP_PASS}';
GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${APP_USER}'@'%';

FLUSH PRIVILEGES;
EOF

echo ">>> DONE. Run 'mysql -u root -p -e \"SHOW MASTER STATUS;\"' để lấy File/Position cho slave."
