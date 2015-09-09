# == Class profile_sensu::server
#
# Installs all of the components necessary to run
# a Sensu server, including rabbitmq, handlers, redis, and Uchiwa.
#
# Does *not* include the `sensu` class. It is assumed that class is
# included by the calling class.
#
# Assumes a mail server is available and installed by another profile.
#
# Should end up profile_sensu/manifests/server.pp
#
class profile_sensu::server {

  class { '::rabbitmq':
  }
  rabbitmq_user { 'sensu': password => 'correct-horse-battery-staple' }
  rabbitmq_vhost { 'sensu': ensure => present }
  rabbitmq_user_permissions { 'sensu@sensu':
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }

  class { '::redis':
  }

 # Required to install some sensu rubygems
  package { 'build-essential': ensure => 'installed' }
  package { 'sensu-plugins-mailer':
    ensure   => 'installed',
    provider => sensu_gem,
  }
  sensu::handler { 'mailer':
    command => '/opt/sensu/embedded/bin/handler-mailer.rb',
    type    => 'pipe',
    config  => {
     "admin_gui"    => "http://localhost:8080/",
     "mail_from"    => "sensu@localhost",
     "mail_to"      => "root@localhost",
     "smtp_address" => "localhost",
     "smtp_port"    => "25",
     "smtp_domain"  => "localhost"
    }
  }

  class { 'uchiwa':
    install_repo => false,
    sensu_api_endpoints => [
      { 'host' => '127.0.0.1' }
    ],
  }

}

# == Class profile_sensu::client
#
# Installs base clients stuff for every Snesu client
# including basic checks.
#
# Should end up in profile_sensu/manifests/client.pp
#
class profile_sensu::client {
  package { 'sensu-plugins-disk-checks':
    ensure   => 'installed',
    provider => sensu_gem,
  }
  # Every Sensu client gets at least a basic disk-check.
  # This is a standalone check, so it applies only to the
  # hosts that this class lives on, regardless of the `subscriptions`
  # it has.
  sensu::check { 'check-disk':
    command => '/opt/sensu/embedded/bin/check-disk-usage.rb',
  }
}

# == Class: profile_sensu
#
# Profile entrypoint for both Sensu servers and clients (and both)
# Should end up in profile_server/manifests/init.pp
#
# === Parameters
#
# [*server*]
# Boolean, set to true if you want to install all of the
# server-related components. (api, handlers, uchiwa, etc)
# Defaults to false.
#
# [*server_host*]
# Used to point to the rabbitmq server. Defaults to localhost.
#
# [*subscriptions*]
# Array of tags for a client to subscribe to. Has no effect on "standalone"
# checks.
#
class profile_sensu (
  $server = false,
  $server_host = 'localhost',
  $subscriptions = [],
) {

  # The main sensu class is included regardless
  # of whether you are a server or not. (all servers are also clients)
  class { '::sensu':
    rabbitmq_host            => $server_host,
    rabbitmq_password        => 'correct-horse-battery-staple',
    server                   => $server,
    api                      => $server,
    subscriptions            => $subscriptions,
    redis_reconnect_on_error => true,
  }
  include profile_sensu::client 
  if $server {
    include profile_sensu::server
  }

}

# Include profile_sensu with stock options. Used for `puppet apply`
# In real life this might go into a Role.
include profile_sensu
