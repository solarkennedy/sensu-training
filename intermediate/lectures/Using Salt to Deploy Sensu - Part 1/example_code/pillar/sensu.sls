sensu:
  server:
    install_gems:
      - sensu-plugins-mailer
  client:
    embedded_ruby: False
  rabbitmq:
    host: localhost
    user: sensu
    password: password
  api:
    user: admin
    password: password
  ssl:
    enable: False
  uchiwa:
    sites:
      site1:
        host: localhost
        user: admin
        password: password
