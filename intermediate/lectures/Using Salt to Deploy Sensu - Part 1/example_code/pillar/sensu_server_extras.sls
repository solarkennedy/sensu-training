sensu_server_extras:
  mailer_configuration:
    handlers:
      mailer:
        type: pipe
        command: /opt/sensu/embedded/bin/handler-mailer.rb
    mailer:
      admin_gui: http://localhost:3000/
      mail_from: sensu@localhost
      mail_to: root@localhost2
      smtp_address: localhost
      smtp_port: 25
      smtp_domain: localhost
