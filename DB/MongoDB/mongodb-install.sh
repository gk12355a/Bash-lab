#!/bin/bash
# Author: Kiên Đỗ Trí
# Script cài đặt MongoDB Replica Set trên Ubuntu 22.04
# Master: 192.168.23.12 (db-master)
# Slave : 192.168.23.13 (db-slave)

set -e

MASTER_IP="192.168.23.12"
SLAVE_IP="192.168.23.13"
REPL_SET="mongo-repli"

echo "[1] Cập nhật /etc/hosts..."
sudo tee -a /etc/hosts > /dev/null <<EOF
$MASTER_IP db-master
$SLAVE_IP db-slave
EOF

echo "[2] Cài đặt MongoDB..."
sudo apt-get update
sudo apt-get install -y gnupg curl

# Thêm GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor

# Thêm repo cho Ubuntu 22.04 (jammy)
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] \
https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" \
  | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

sudo apt-get update
sudo apt-get install -y mongodb-org

echo "[3] Cấu hình mongod.conf..."
LOCAL_IP=$(hostname -I | awk '{print $1}')

sudo tee /etc/mongod.conf > /dev/null <<EOF
storage:
  dbPath: /var/lib/mongodb

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 127.0.0.1,$LOCAL_IP

replication:
  replSetName: $REPL_SET
EOF

echo "[4] Khởi động MongoDB..."
sudo systemctl daemon-reexec
sudo systemctl enable --now mongod

echo "✅ Cài đặt MongoDB hoàn tất trên $LOCAL_IP"
echo "👉 Nếu đây là DB-master ($MASTER_IP), hãy đăng nhập mongosh và chạy:"
echo "    rs.initiate({ _id: \"$REPL_SET\", members: [{ _id: 0, host: \"db-master:27017\" }] })"
echo "    rs.add(\"db-slave:27017\")"

# chạy trên master
# rs.initiate({ _id: "mongo-repli", members: [{ _id: 0, host: "db-master:27017" }] })
# rs.add("db-slave:27017")
# use admin
# db.createUser({
#   user: "mongo-admin",
#   pwd: "Tech@1604",
#   roles: [{ role: "root", db: "admin" }]
# })
# login lại bằng cách 
# mongosh --host db-master:27017 --username mongo-admin --password Tech@1604 --authenticationDatabase admin
# MongoDB Cheatsheet - 20 Câu lệnh phổ biến
# ============================================================

# [Quản lý Database]
# - show dbs
#     Xem tất cả database
# - use mydb
#     Chọn hoặc tạo database
# - db
#     Xem database hiện tại
# - db.dropDatabase()
#     Xóa database hiện tại

# [Quản lý Collection]
# - show collections
#     Xem tất cả collection
# - db.createCollection("users")
#     Tạo collection
# - db.users.drop()
#     Xóa collection

# [Thao tác Document]
# - db.users.insertOne({ name: "Alice", age: 25 })
#     Thêm document
# - db.users.insertMany([{ name: "Bob", age: 30 }, { name: "Carol", age: 27 }])
#     Thêm nhiều document
# - db.users.find()
#     Xem tất cả document
# - db.users.find({ age: { $gt: 25 } })
#     Tìm với điều kiện
# - db.users.updateOne({ name: "Alice" }, { $set: { age: 26 } })
#     Cập nhật 1 document
# - db.users.updateMany({ age: { $lt: 30 } }, { $set: { status: "young" } })
#     Cập nhật nhiều document
# - db.users.deleteOne({ name: "Bob" })
#     Xóa 1 document
# - db.users.deleteMany({ status: "young" })
#     Xóa nhiều document

# [Truy vấn nâng cao]
# - db.users.find().sort({ age: -1 })
#     Sắp xếp kết quả (giảm dần)
# - db.users.find().limit(5)
#     Giới hạn số lượng kết quả
# - db.users.countDocuments()
#     Đếm số document
# - db.users.createIndex({ name: 1 })
#     Tạo index
# - db.users.getIndexes()
#     Xem các index

# [Replica Set (Bonus)]
# - rs.status()
#     Xem trạng thái replica set
# - rs.conf()
#     Xem cấu hình replica set
