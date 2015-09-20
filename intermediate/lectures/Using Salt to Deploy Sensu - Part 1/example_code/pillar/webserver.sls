webserver:
  check_http_configuration:
    checks:
      check_http:
        command: /opt/sensu/embedded/bin/check-http.rb --url "http://localhost/"
        standalone: true
        interval: 60
        handlers: ['mailer']
