#!/bin/bash
set -euxo pipefail

RABBITMQ_USER="${rabbitmq_user}"
RABBITMQ_PASS="${rabbitmq_password}"
PROJECT_NAME="${project_name}"

dnf update -y
dnf install -y erlang socat logrotate awscli

RABBITMQ_VERSION="3.13.7"
curl -fsSL "https://github.com/rabbitmq/rabbitmq-server/releases/download/v$${RABBITMQ_VERSION}/rabbitmq-server-$${RABBITMQ_VERSION}-1.el8.noarch.rpm" \
  -o /tmp/rabbitmq-server.rpm
rpm --import https://github.com/rabbitmq/rabbitmq-server/releases/download/v$${RABBITMQ_VERSION}/rabbitmq-server-$${RABBITMQ_VERSION}-1.el8.noarch.rpm.asc 2>/dev/null || true
dnf install -y /tmp/rabbitmq-server.rpm

/usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management

cat > /etc/rabbitmq/rabbitmq.conf << 'RABBITCONF'
loopback_users.guest = false
listeners.tcp.default = 5672
management.tcp.port = 15672
vm_memory_high_watermark.relative = 0.8
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_classic_config
RABBITCONF

mkdir -p /etc/rabbitmq/definitions

cat > /etc/rabbitmq/definitions/definitions.json << DEFS
{
  "rabbit_version": "3.13.7",
  "users": [
    {"name": "dummy", "password_hash": "dummy", "hashing_algorithm": "rabbit_password_hashing_sha256", "tags": ""}
  ],
  "vhosts": [{"name": "/"}],
  "permissions": [],
  "topic_permissions": [],
  "parameters": [],
  "global_parameters": [{"name": "cluster_name", "value": "awsticket"}],
  "policies": [
    {
      "name": "dlx-tickets",
      "vhost": "/",
      "pattern": "^tickets\\.buy$",
      "apply-to": "queues",
      "definition": {
        "dead-letter-exchange": "tickets.dlx",
        "dead-letter-routing-key": ""
      },
      "priority": 1
    }
  ],
  "queues": [
    {"name": "tickets.buy", "vhost": "/", "durable": true, "auto_delete": false, "arguments": {"x-queue-type": "quorum"}},
    {"name": "tickets.dlq", "vhost": "/", "durable": true, "auto_delete": false, "arguments": {"x-queue-type": "quorum"}}
  ],
  "exchanges": [
    {"name": "tickets", "vhost": "/", "type": "direct", "durable": true, "auto_delete": false, "internal": false},
    {"name": "tickets.dlx", "vhost": "/", "type": "direct", "durable": true, "auto_delete": false, "internal": false}
  ],
  "bindings": [
    {"source": "tickets", "vhost": "/", "destination": "tickets.buy", "destination_type": "queue", "routing_key": "buy", "arguments": {}},
    {"source": "tickets.dlx", "vhost": "/", "destination": "tickets.dlq", "destination_type": "queue", "routing_key": "", "arguments": {}}
  ]
}
DEFS

echo 'SERVER_ADDITIONAL_ERL_ARGS=-rabbitmq_management load_definitions "/etc/rabbitmq/definitions/definitions.json"' > /etc/rabbitmq/rabbitmq-env.conf

systemctl enable rabbitmq-server
systemctl start rabbitmq-server

for i in $(seq 1 30); do
    if rabbitmqctl await_startup 2>/dev/null; then
        break
    fi
    sleep 2
done

rabbitmqctl add_user "$${RABBITMQ_USER}" "$${RABBITMQ_PASS}"
rabbitmqctl set_user_tags "$${RABBITMQ_USER}" administrator
rabbitmqctl set_permissions -p / "$${RABBITMQ_USER}" ".*" ".*" ".*"
rabbitmqctl delete_user guest 2>/dev/null || true
rabbitmqctl delete_user dummy 2>/dev/null || true

echo "RabbitMQ setup complete"
