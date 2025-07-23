For Redis:

Connect to Redis CLI:
bash
At mention
redis-cli
Check Redis stats:
bash
At mention
INFO stats
Monitor keyspace:
bash
At mention
INFO keyspace
Watch real-time operations:
bash
At mention
MONITOR
For RabbitMQ:

Check queue status:
bash
At mention
sudo rabbitmqctl list_queues
View connections:
bash
At mention
sudo rabbitmqctl list_connections
Check channels:
bash
At mention
sudo rabbitmqctl list_channels
Monitor messages:
bash
At mention
sudo rabbitmqctl list_consumers
Would you like me to help you:

Set up monitoring dashboards
Create log files for these services
Check specific queue/connection details?
Planned for 7s

View Plan
Here’s a summary of the plan update:

Added notes about the resolved import/export naming issue between 
courseRoute.js
 and 
courseController.js
.
Added a checklist for fixing the route/controller import, confirming server startup, and next steps for monitoring Redis and RabbitMQ on CentOS.
Set the current goal to "Guide Redis/RabbitMQ monitoring on CentOS".
Now updating the plan file accordingly.

Completed
Diagnose and fix import/export mismatch in course routes/controllers
Confirm server and service startup (Redis, RabbitMQ, DB)
Added
Provide commands and/or setup for monitoring Redis and RabbitMQ on CentOS 9
Based on your request to monitor Redis and RabbitMQ on your CentOS 9 server (192.168.23.11), here are some additional advanced monitoring options:

For Redis (More Detailed Monitoring):

Check memory usage:
bash
redis-cli info memory
View all keys (careful in production):
bash
redis-cli --scan --pattern '*'
Get slow log (shows slow queries):
bash
redis-cli slowlog get 10
For RabbitMQ (More Detailed Monitoring):

View detailed queue info:
bash
sudo rabbitmqctl list_queues name messages_ready messages_unacknowledged
Check message rates:
bash
sudo rabbitmqctl list_queues name messages messages_ready messages_unacknowledged idle_since
View exchange bindings:
bash
sudo rabbitmqctl list_bindings