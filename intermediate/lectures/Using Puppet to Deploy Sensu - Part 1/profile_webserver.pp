# == Class: profile_webserver
#
# Example profile that combines an apache module and the Sensu module
# together in a cohesive way.
#
# Demonstrates how to tightly bind a piece of software and the *monitoring*
# of that software together.
#
# === Parameters
#
# [*port*]
# Port for apache to bind on *and* for the check_http to check for.
# If you change the port for apache, the check will follow it.
#
class profile_webserver (
  $port = 80,
) {

  class { 'apache':
    listen_on => $port,
  } ->
  package { 'sensu-plugins-http-checks':
    ensure   => 'installed',
    provider => sensu_gem,
  } ->
  sensu::check { 'check_apache':
    command => "/opt/sensu/embedded/bin/check-http.rb --port ${port} --host localhost",
  }

}
