# -*- coding: utf-8 -*-
import os
import psutil
import matplotlib.pyplot as plt
from datetime import datetime

# --- CONFIG ---
duration = 60  # Thời gian lấy mẫu (giây)
interval = 5   # Khoảng cách lấy mẫu (giây)
log_dir = "/var/log/monitor"  # Thư mục log trên Server B
log_file = os.path.join(log_dir, "sys_usage_log")

# Đảm bảo thư mục tồn tại
os.makedirs(log_dir, exist_ok=True)

# --- STEP 1: GHI LOG HỆ THỐNG ---
def log_system_usage():
    with open(log_file, "w", encoding="utf-8") as f:
        f.write("timestamp,cpu,ram,disk\n")
        start_time = time.time()
        while time.time() - start_time < duration:
            cpu = psutil.cpu_percent(interval=1)
            ram = psutil.virtual_memory().percent
            disk = psutil.disk_usage("/").percent
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            f.write(f"{timestamp},{cpu},{ram},{disk}\n")
            time.sleep(interval)

# --- STEP 2: VẼ BIỂU ĐỒ ---
def plot_usage_graph(timestamps, cpus, rams, disks):
    plt.figure(figsize=(10, 6))
    plt.plot(timestamps, cpus, label="CPU (%)", color="black")
    plt.plot(timestamps, rams, label="RAM (%)", color="red")
    plt.plot(timestamps, disks, label="Disk (%)", color="green")
    plt.xlabel("Time")
    plt.ylabel("Usage (%)")
    plt.title("System Resource Usage on Server B")
    plt.xticks(rotation=45)
    plt.legend()
    plt.tight_layout()
    plt.grid(True)

    # Tạo thư mục và lưu biểu đồ
    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    img_dir = f"/var/log/monitor_logs/{date_str}"
    os.makedirs(img_dir, exist_ok=True)
    img_path = os.path.join(img_dir, f"sys_usage_chart_{timestamp}.png")
    plt.savefig(img_path)
    print(f"[{timestamp}] Saved chart: {img_path}")

    # Lưu dữ liệu CSV
    csv_path = os.path.join(log_dir, date_str, f"sys_usage_{date_str}.csv")
    os.makedirs(os.path.dirname(csv_path), exist_ok=True)
    with open(csv_path, "a", encoding="utf-8") as f:
        f.write(f"{now.isoformat()},{img_path}\n")

# --- CHẠY CHƯƠNG TRÌNH ---
if __name__ == "__main__":
    timestamps, cpus, rams, disks = log_system_usage()
    plot_usage_graph(timestamps, cpus, rams, disks)