rabbitmq:
  vhost:
    '/sensu':
      - owner: sensu
      - conf: .*
      - write: .*
      - read: .*
  user:
    sensu:
      - password: password
      - perms:
        - '/sensu':
          - '.*'
          - '.*'
          - '.*'
