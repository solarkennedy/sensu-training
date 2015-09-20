sensu-plugins-disk-checks:
  gem.installed:
    - gem_bin: /opt/sensu/embedded/bin/gem

/etc/sensu/conf.d/check_disk.json:
  file.managed:
    - contents: '{{ pillar["sensu_client_extras"]["check_disk_configuration"] | json() }}'
    - watch_in:
      - service: sensu-client
