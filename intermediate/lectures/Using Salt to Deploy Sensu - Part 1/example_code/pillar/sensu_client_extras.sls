sensu_client_extras:
  check_disk_configuration:
    checks:
      check_disk:
        command: /opt/sensu/embedded/bin/check-disk-usage.rb
        standalone: true
        interval: 60
        handlers: ['mailer']
