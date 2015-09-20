include:
  - apache

sensu-plugins-http:
  gem.installed:
    - gem_bin: /opt/sensu/embedded/bin/gem

/etc/sensu/conf.d/check_http.json:
  file.managed:
    - contents: '{{ pillar["webserver"]["check_http_configuration"] | json() }}'
    - watch_in:
      - service: sensu-client

