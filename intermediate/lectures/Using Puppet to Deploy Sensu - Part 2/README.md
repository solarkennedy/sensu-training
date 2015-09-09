## Using Puppet With Sensu - Part 2

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

#### Mailer Configuration 

Now how about configuring the handler? There is a puppet type for
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

ets take a look at where puppet is putting this stuff:

    cd /etc/sensu/conf.d/

You can see that this is pre-organized for you. Lets look at handlers

    cd handlers
    cat mailer.json

Everything is nice and tidy. Made by a machine!

### Installing Checks

Sensu doesn't do much unless we install a check for clients to execute.

This time lets try out the same sensu disk check we used from the
introduction course::
https://github.com/sensu-plugins/sensu-plugins-disk-checks

Asking puppet to install this is easy with the `sensu_gem` type:

```puppet
package { 'sensu-plugins-disk-checks':
  ensure   => 'installed',
  provider => sensu_gem,
}
```

At this point you should be thinking to yourself, wait a minute
Kyle, I know how Sensu works internally, I watched your introductory
course and I know that the Sensu Server never executes checks, only
the clients! You are 100% correct. This code shoud only be installed on
a client. In this particular case we are running the client and server
on the same machine. Later I'll split this out and show what a
client-only puppet class might look like.

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

## Installing Uchiwa with Puppet

The official Sensu puppet module links to this puppet module as the recommended
way of installing and configuring Uchiwa with Puppet.

Lets install this one:

    puppet module install yelp-uchiwa

And now we can include the Uchiwa class with our existing server stuff:

    class { 'uchiwa': }

And now we have another very common error. In puppet, the same resource cannot
be declared twice. In this case, both Uchiwa and the Sensu puppet module are
trying to declare the sensu repo.

The solution here is to tell one of them not to manage the repo. In this case
it is easiest to just tell the `uchiwa` puppet module to not manage the repo:

    class { 'uchiwa':
      manage_repo => false,
    }

Apply, and now lets look at it with our browser:

    xdg-open http://localhost:3000

It looks like it isn't working still? Let's look at the logs and see why that
might be:

    tail /var/log/uchiwa.log

It looks like the configuration file might be missing the `host` setting. Let's
look at the file

    cat /etc/sensu/uchiwa.json

This is odd, because on github it looks like this bug has been fixed already, but
on the version of the module that we downloaded from the forge, it isn't.

That is ok, we can manually specify our api endpoints ourselves:

    class { 'uchiwa':
      manage_repo => false,
      sensu_api_endpoints => [
        { 'host' => '127.0.0.1' }
      ],
    }

And now it is working. Minus that small bug, you can see how we could potentially
grow this configuration to include more Sensu endpoints. Possible for showing both
a production and development environment, or perhaps multiple stage environments.

## What Would a Client Look Like?

This may be fine for a server, but what if we were just configuring a client?

    vim profile_sensu_client.pp

We will need the sensu module, for sure:

```puppet
class { 'sensu':
}
```

At the very least we need to give it the same credentials we made early on,
so that our Sensu clients can connect to RabbitMQ and deposit their check
results:

    rabbitmq_password => 'correct-horse-battery-staple'

And while the server was just a server, our client will need the RabbitMQ
hostname too:

    rabbitmq_host => 'localhost',

And if you intend to use Sensu with subscription based checks, remember those
are checks that are scheduled by the Sensu Server, then we will need to configure
the Sensu client with which subscriptions it should respond to:

    subscriptions  => ['webserver', 'production'],

Is that it? It is not. The Sensu client is the *only* thing that actually
executes checks. That means the Sensu client *must* have the Sensu plugins
available on disk to run. This means that `check-disk` script, or `check_http`,
or whatever, have to exist on the client.

```puppet
package { ['sensu-plugins-disk-checks', 'sensu-plugins-http-checks']:
  ensure   => 'installed',
  provider => sensu_gem,
}
```

Now, if desired you can configure standalone checks on clients as well.
This makes the most sense to me in a puppet-configured world. Imagine
you already have a class that defines how you configure a webserver:

```pupppet
class profile_webserver (
  $port = 8080,
){

  class { 'apache':
    listen_port => $port,
  }

}
```

Wouldn't it be great if you could get the monitoring to go right with it?

```puppet
class { 'apache':
  listen_port => $port,
} ->
sensu::check { 'check_apache':
  command => "/opt/sensu/embedded/bin/check-http.rb --port ${port} --host localhost",
}
```

Now you can apply this apache class to whatever machine you want, and the
monitoring will go with it. There is really good cohesion between your
configuration of your software and the monitoring of that software.

Because these are standalone checks, they apply no matter what subscriptions
the Sensu client is subscribed to. That means if you applied this class
to your production webserver, or if it was applied to some app server, both
would get the same monitoring. I think this is just great!

To re-iterate though, I don't think that the monitoring itself belongs
*in* the apache module. No, the Apache module can just do its thing:
install apache. It is the "profile" that combines the two together.
In this particular instance I called it `profile_webserver`, because
that is the particular function it does.

## Conclusion

Sensu was designed to be used with configuration management, and with
puppet it really shows. The Sensu puppet module is a *first-class*
citizen in the puppet world, it can do pretty much anything.

And in the end you *want* it to do everything. More specifically,
you want to make the most out of this automation so that you
deploy reproducible infrastructure, that you never have to
"remember" to add it to Nagios or whatever. With Puppet and Sensu,
there is a really good bond between the software and the monitoring.
