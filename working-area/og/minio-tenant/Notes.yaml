# Minio-Tenant
#name: minio-tenant
#namespace: default
redundantServers: 1

rootUserName: "root"
rootUserPassword: "root"

webhookEndpoints:
  rabbtmq_notifications:
    comment: RabbitMQ tiggers for Pusher
    endpoint: http://rabbtmq.rabbitmq-cluster/

Creates a secret named ?-env-configuration
exports:
MINIO_STORAGE_CLASS_STANDARD"EC:{{redundantServers}}"
MINIO_BROWSER="on"
MINIO_ROOT_USER
MINIO_ROOT_PASSWORD
MINIO_PROMETHEUS_UR
MINIO_NOTIFY_WEBHOOK_ENABLE_{{ $webhook_id }}="on"
MINIO_NOTIFY_WEBHOOK_{{$webhook_property | snakecase | upper}}_{{$webhook_id}}={{$webhook_value}}


# Loki-Tenant
Creates 2 secrets named metrics-env-configuration and metrics user-0
exports:
MINIO_STORAGE_CLASS_STANDARD"EC:{{redundantServers}}"
MINIO_BROWSER="on"
MINIO_ROOT_USER={hardcoded}
MINIO_ROOT_PASSWORD={hardcoded}
MINIO_PROMETHEUS_UR

## Secret
stringData:
  CONSOLE_ID:
  CONSOLE_KEY: 
