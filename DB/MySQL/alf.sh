#!/bin/bash
set -e

MASTER_IP="192.168.23.12"
SLAVE_IP="192.168.23.13"
SSH_USER="your_ssh_user"   # đổi thành user SSH thật, ví dụ ubuntu

echo "[STEP] Update hosts"
sudo tee -a /etc/hosts > /dev/null <<EOF
192.168.23.11 alf
192.168.23.12 DB-master
192.168.23.13 DB-slave
EOF

echo "[STEP] Install ProxySQL"
sudo tee /etc/yum.repos.d/proxysql.repo > /dev/null <<'EOF'
[proxysql]
name=ProxySQL YUM repository
baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.7.x/centos/9/
gpgcheck=1
gpgkey=https://repo.proxysql.com/ProxySQL/repo_pub_key
enabled=1
EOF

sudo dnf makecache
sudo dnf install -y proxysql mysql
sudo systemctl enable --now proxysql

# 🔹 Chờ ProxySQL admin interface lên port 6032
echo "[STEP] Waiting for ProxySQL admin interface..."
for i in {1..10}; do
  if mysqladmin ping -u admin -padmin -h 127.0.0.1 -P6032 >/dev/null 2>&1; then
    echo "ProxySQL is ready!"
    break
  else
    echo "ProxySQL not ready, retrying in 2s..."
    sleep 2
  fi
done

echo "[STEP] Configure ProxySQL"
mysql -u admin -padmin -h 127.0.0.1 -P6032 <<EOF
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (1, '${MASTER_IP}', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (2, '${SLAVE_IP}', 3306);
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES ('app_user', 'Tech@1604', 1);

INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply)
VALUES (1, 1, '^SELECT.*FOR UPDATE', 1, 1);
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply)
VALUES (2, 1, '^SELECT', 2, 1);
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply)
VALUES (3, 1, '.*', 1, 1);

LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL USERS TO DISK;
SAVE MYSQL QUERY RULES TO DISK;
EOF

echo "[STEP] Install MHA Manager"
sudo dnf install -y perl-DBI perl-DBD-MySQL
wget -O /tmp/mha-manager.rpm https://github.com/yoshinorim/mha4mysql-manager/releases/download/v0.58/mha4mysql-manager-0.58-0.el7.centos.noarch.rpm
sudo dnf install -y /tmp/mha-manager.rpm || true

echo "[STEP] Create update_proxysql.sh"
sudo tee /etc/mha/update_proxysql.sh > /dev/null <<'EOF'
#!/bin/bash
NEW_MASTER_IP=$1
OLD_MASTER_IP=$2
mysql -u admin -padmin -h 127.0.0.1 -P6032 <<SQL
UPDATE mysql_servers SET hostname='$NEW_MASTER_IP' WHERE hostgroup_id=1;
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
SQL
EOF
sudo chmod +x /etc/mha/update_proxysql.sh

echo "[STEP] Create /etc/mha/app1.cnf (manual edit required)"
sudo tee /etc/mha/app1.cnf > /dev/null <<EOF
[server default]
user=root
password=YOUR_ROOT_PASSWORD
ssh_user=${SSH_USER}
repl_user=replica_user
repl_password=Tech@1604
manager_workdir=/var/log/mha/app1
manager_log=/var/log/mha/app1.log
master_ip_failover_script=/etc/mha/update_proxysql.sh

[server1]
hostname=${MASTER_IP}
port=3306
candidate_master=1

[server2]
hostname=${SLAVE_IP}
port=3306
candidate_master=1
EOF

sudo mkdir -p /var/log/mha/app1
sudo chown $(whoami):$(whoami) /var/log/mha/app1

echo ">>> DONE. Nhớ chỉnh YOUR_ROOT_PASSWORD trong /etc/mha/app1.cnf"
echo ">>> Sau đó chạy:"
echo "masterha_check_ssh --conf=/etc/mha/app1.cnf"
echo "masterha_check_repl --conf=/etc/mha/app1.cnf"
echo "masterha_manager --conf=/etc/mha/app1.cnf"
