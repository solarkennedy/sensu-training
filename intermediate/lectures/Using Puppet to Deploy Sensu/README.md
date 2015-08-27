## Using Puppet With Sensu

### Intro

If you use Puppet in your environment, or you would like it, I have some good news: Puppet plus Sensu is a pretty good combination.

https://github.com/sensu/sensu-puppet
https://github.com/Yelp/puppet-uchiwa

### Getting Started

I'm not going to run puppet in full client-server mode for this lesson. There
is plenty of other documentation on that, for this lecture I'm just going to
focus on Sensu-specific stuff.

This server that I'm on is freshly imaged, I have not tricks up my sleeve here.
Everything will be from scratch.

Every external puppet module I use and code samples or fragments will be
available in the external resources section, so don't worry about missing an
exact command or try to copy paste from the video.

In fact, if things change, and they do change, I'm much more likely to keep the
external resources section up to date, and not re-record the video, so just
keep that in mind.

### Just Getting Puppet

Getting puppet in the first place is easy with a modern distro. I don't need
any fancy features, whatever the distro has is fine.

    sudo su -
    apt-get install -y puppet

This vagrant box happens to come with puppet already because it is a supported
provisioning tools for building vagrant boxes, so we are ready to start.

### RabbitMQ

Just like in the Introduction lecture, the first thing I want to get in place
is RabbitMQ.  To do that, I'm going to install the official Puppetlabs RabbitMQ
module:

    puppet module install puppetlabs/rabbitmq

If you have never used the puppet module tool like that before, it just gets
the latest release of the rabbitmq module from the puppet forge and makes it
available for use. I don't have to know much about how it works, I just have to
know how to interface with it in my puppet code.

    vim server.pp

```puppet
class { '::rabbitmq': }
 ```

    puppet apply sensu-server.pp

Isn't configuration management just great? With one line of puppet code
we did what took an entire lecture in the introductory course.

Now we are getting away with lots of good defaults here. You can of course
always read up on the exact api that is provided here, tweak inputs, etc:
https://forge.puppetlabs.com/puppetlabs/rabbitmq

### Redis

Sometimes on the puppet forge it is not obvious which redis module is
right for you, but Puppetlabs has done a good job of improving the situation.

By simply filtering only the "Puppetlabs approved" modules, you can be sure
that it is decent, has tests, is well maintained, etc.

    puppet module install arioch-redis
    vim sensu-server.pp

```puppet 
class { '::rabbitmq': }
class { '::redis': }
```

    puppet apply sensu-server.pp
    redis-cli ping

So great. Again lots of good defaults here, and room to tweak.

### Sensu

The Sensu puppet module is built and maintained under the Sensu
project itself. It is a well-supported module.

https://forge.puppetlabs.com/sensu/sensu

    puppet module install sensu-sensu

Now one of these modules is probably a bit too agressive with their
pinning to very specifc version of pupppetlabs-apt here. I'm pretty sure
this is just really conservative settings and that we can ignore this:

    puppet module install sensu-sensu --ignore-dependencies

```puppet
class { '::rabbitmq': }
class { '::redis': }
class { '::sensu': }
```

    puppet apply sensu-server.pp

You can see quite a bit of deprecation warnings. At this exact moment in time it looks like the
puppetlabs apt module is in a flux and the API is changing. Luckily these are just deprecation
warnings and this should still work.

### More Configuration

Well we are going to have to provide *some* configuration to this. By default the
Sensu puppet module does not assume you are installing a sensu server.

Lets look at the docs:
https://forge.puppetlabs.com/sensu/sensu#basic-example

For a sensu server we will need a rabbitmq password, and we'll want to enable the
server and api toggles. We'll work on handlers, checks, and plugins later.

```puppet
class { '::sensu':
  rabbitmq_password => 'correct-horse-battery-staple',
  server            => true,
  api               => true,
}
```

This module leaves it up to you to configure the rabbitmq part. Simply telling
Sensu what rabbitmq password to use will not magically make it show up. We
need more *puppet* magic of course:
https://forge.puppetlabs.com/puppetlabs/rabbitmq#native-types

Just like in the official documentation:
https://sensuapp.org/docs/latest/install-rabbitmq#configure-rabbitmq

We will have to figure out how to do that with puppet.

```puppet
rabbitmq_user { 'sensu': password => 'correct-horse-battery-staple' }
rabbitmq_vhost { 'sensu': ensure => present }
rabbitmq_user_permissions { 'sensu@sensu':
  configure_permission => '.*',
  read_permission      => '.*',
  write_permission     => '.*',
}
```

I'm pretty sure this maps with what the official documentation has.

    puppet apply sensu-server.pp

Does it work?

    tail /var/log/sensu/sensu-server.log
    tail /var/log/sensu/sensu-client.log

It looks like it I guess. We don't have any checks or anything installed, so it is
a bit hard to tell. Lets get some real checks going next.

## Installing the Email Handler

In the introductory course we installed the `sensu-plugins-mailer` gem to install
an email handler for Sensu?
https://github.com/sensu-plugins/sensu-plugins-mailer

Lets do that same thing but as puppet code. Luckily the Sensu puppet
module has a type exactly for this:
https://forge.puppetlabs.com/sensu/sensu#installing-gems-into-the-embedded-ruby

```puppet
package { 'sensu-plugins-mailer':
  ensure   => 'installed',
  provider => sensu_gem,
}
```

Pretty easy. Now how about configuring the handler? There is a puppet type for
that too:
https://forge.puppetlabs.com/sensu/sensu#handler-configuration

```puppet
sensu::handler {
  'mailer':
    command => '/opt/sensu/embedded/bin/handler-mailer.rb',
    type    => 'pipe',
    config  => {
      'foobar_setting' => 'value',
  }
}
```

For the command you should use the full path to the ruby script.
The type is "pipe" because this is a standard handler that accepts event
data on standard in.

The config is a hash of settings. Lets copy in what the docs have, and then
port it to puppet:

```
{
  "admin_gui": "http://admin.example.com:8080/",
  "mail_from": "sensu@example.com",
  "mail_to": "monitor@example.com",
  "smtp_address": "smtp.example.org",
  "smtp_port": "25",
  "smtp_domain": "example.org"
}
```

```pupppet
    config  => {
      'admin_gui'    => 'http://localhost:3000/',
      'mail_from'    => 'sensu@localhost',
      'smtp_address' => 'localhost',
      'smtp_port'    => '25',
      'smtp_domain'  => 'localhost'
  }
```

Apply....

Arg, an error:

```
Building native extensions.  This could take a while...
ERROR:  Error installing sensu-plugins-mailer:
	ERROR: Failed to build gem native extension.

    /opt/sensu/embedded/bin/ruby extconf.rb

Gem files will remain installed in /opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/unf_ext-0.0.7.1 for inspection.
Results logged to /opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/unf_ext-0.0.7.1/ext/unf_ext/gem_make.out
```
This is very common one, you can google for this, but the spoiler alert here
is that when you install gems you often need a compiler and stuff. On
ubuntu you can get most of the common packages you need for this with
the build-essential package. You know, we could install this package manually,
but how reproducible would that be?


    package { 'build-essential': ensure => installed }

Lets take a look at where puppet is putting this stuff:

    cd /etc/sensu/conf.d/

You can see that this is pre-organized for you. Lets look at handlers

    cd handlers
    cat mailer.json

Everything is nice and tidy. Made by a machine!

### Installing Checks

In the introductory we had a disk check installed from the Nagios plugins package.
This time lets try out the equivilant sensu-plugin:
https://github.com/sensu-plugins/sensu-plugins-disk-checks

Asking puppet to install this is easy with the `sensu_gem` type:

```puppet
package { 'sensu-plugins-disk-checks':
  ensure   => 'installed',
  provider => sensu_gem,
}
```

That installs the check, but how do we turn it on in Sensu?
https://forge.puppetlabs.com/sensu/sensu#sensu-client-1

```puppet
sensu::check { 'check-disk':
  command => '/opt/sensu/embedded/bin/check-disk-usage.rb',
}
```

That is just an example, we'll have to clean up the command.
If you ever forget what the actuall script filenames are called,
you can always just look on github in the "bin" folder for a particular gem:
https://github.com/sensu-plugins/sensu-plugins-disk-checks/tree/master/bin

Lets apply..

And where did Puppet put this stuff?

    cd /etc/sensu/conf.d/checks
    cat check-disk.json

You can see the defaults for this in sensu is to have it check every minute,
that is the interval of 60. Also this is a standalone check by default,
which means this check definition will apply to the hosts that you define
it on, which makes the most sense in a puppet world.

Well we applied this puppet code, in theory puppet made everything happen,
restarted the things that need to be restarted, etc. How do the logs look?

    tail -f /var/log/sensu/sensu-client.log
    tail -f /var/log/sensu/sensu-server.log

