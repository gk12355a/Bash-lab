# -*- coding: utf-8 -*-
import os
import psutil
import time
import matplotlib.pyplot as plt
from datetime import datetime

# --- CONFIG ---
log_file = "/var/log/monitor_logs/sys_usage.log"
duration = 60  # Thời gian lấy mẫu (giây)
interval = 5   # Khoảng cách lấy mẫu (giây)

# --- STEP 1: GHI LOG ---
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
def plot_usage_graph():
    timestamps, cpus, rams, disks = [], [], [], []
    with open(log_file) as f:
        next(f)  # Bỏ header
        for line in f:
            ts, cpu, ram, disk = line.strip().split(",")
            timestamps.append(ts[11:])  # Lấy HH:MM:SS
            cpus.append(float(cpu))
            rams.append(float(ram))
            disks.append(float(disk))

    plt.figure(figsize=(10, 6))
    plt.plot(timestamps, cpus, label="CPU (%)")
    plt.plot(timestamps, rams, label="RAM (%)")
    plt.plot(timestamps, disks, label="Disk (%)")
    plt.xlabel("Time")
    plt.ylabel("Usage (%)")
    plt.title("System Resource Usage")
    plt.xticks(rotation=45)
    plt.legend()
    plt.tight_layout()
    plt.grid(True)

    # Tạo thư mục và lưu biểu đồ
    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    img_dir = f"/var/log/monitor_logs/{date_str}"
    os.makedirs(img_dir, exist_ok=True)
    img_path = os.path.join(img_dir, f"sys_usage_chart.png")
    plt.savefig(img_path)
    print(f"[{date_str}] Saved chart: {img_path}")

    # Saved chart: (img_path)

# --- STEP 3: DỌN LOG (tùy chọn) ---
def cleanup_log():
    if os.path.exists(log_file):
        os.remove(log_file)

# --- CHẠY CHƯƠNG TRÌNH ---
if __name__ == "__main__":
    log_system_usage()
    plot_usage_graph()
    # cleanup_log()  # Bỏ comment nếu muốn xóa log sau khi vẽ
    print("/var/log/monitor_logs/sys_usage_chart.png")