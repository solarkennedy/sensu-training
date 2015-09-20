build-essential:
  pkg.installed: []


/etc/sensu/conf.d/mailer.json:
  file.managed:
    - contents: '{{ pillar["sensu_server_extras"]["mailer_configuration"] | json() }}'
    - watch_in:
      - service: sensu-server
