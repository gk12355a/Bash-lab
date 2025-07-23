sudo rabbitmqctl list_queues -p / name | tail -n +2 | while read queue; do
  echo "🔄 Đang xóa queue: $queue"
  sudo rabbitmqctl delete_queue -p / "$queue"
done

echo "✅ Hoàn tất!"
