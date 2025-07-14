String needs to be sealed and deployed, SHOULD prevent the operator from creating another

data:
    default_user.conf: |
        default_user:
        default_pass:
    host: rabbitmq.namespace.svc
    password: <default_pass>
    port: 5672
    provider: rabbitmq
    type: rabbitmq
    username: <default_user>