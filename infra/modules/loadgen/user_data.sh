#!/bin/bash
set -euxo pipefail

RABBITMQ_HOST="${rabbitmq_host}"
RABBITMQ_USER="${rabbitmq_user}"
RABBITMQ_PASS="${rabbitmq_pass}"
PROJECT_NAME="${project_name}"

dnf update -y
dnf install -y git python3.11 python3.11-pip awscli

# El generador de carga se ejecutará manualmente o via script
# Aquí solo preparamos el entorno. El código del generador
# se subirá o clonará después del despliegue.

echo "Load generator instance ready"
echo "RabbitMQ endpoint: $${RABBITMQ_HOST}"
