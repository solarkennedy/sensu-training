## Using Puppet With Sensu

### Intro

If you use Puppet in your environment, or you would like it, I have some good
news: Puppet plus Sensu is a pretty good combination.

This lecture is going to focus mostly on these two puppet modules:

https://github.com/sensu/sensu-puppet
https://github.com/Yelp/puppet-uchiwa

We'll talk about how to put them together to reproduce everything we did in
the introductory course, that is, a fullly working Sensu setup with checks,
handlers, and dashboard.

### Getting Started

I'm not going to run puppet in full client-server mode for this lesson. There
is plenty of other documentation on that, for this lecture I'm just going to
focus on Sensu-specific stuff. To do that, I'm going to write puppet code
and just use the `puppet apply` command to apply it.

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

But we have to start with some puppet code somewhere. I'm going to write it
down in a file, lets call it `profile_sensu.pp`. I'm a fan of Puppet's
role/profile/module pattern, which suggest that we make what is called a
profile, to tie together all the different modules together to make a Sensu
server:

    vim profile_sensu.pp

```puppet
class { '::rabbitmq': }
 ```

    puppet apply profile_sensu.pp

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
    vim profile_sensu.pp

```puppet 
class { '::rabbitmq': }
class { '::redis': }
```

    puppet apply profile_sensu.pp
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

    puppet apply profile_sensu.pp

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
Sensu what rabbitmq password to use will not magically make it show up. We need
more *puppet* magic of course:
https://forge.puppetlabs.com/puppetlabs/rabbitmq#native-types

Just like in the official documentation:
https://sensuapp.org/docs/latest/install-rabbitmq#configure-rabbitmq

We will have to figure out how to do that with puppet.

But before we actually do that, let's apply what we have to see what it looks
like when it *doesn't* work:

    puppet apply profile_sensu.pp
    tail -f /var/log/sensu/sensu-server.log


Now let's do the other part, and configure rabbitmq for Sensu:

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

    puppet apply profile_sensu.pp

Does it work?

    tail /var/log/sensu/sensu-server.log
    tail /var/log/sensu/sensu-client.log

It looks like it I guess. We don't have any checks or anything installed, so it is
a bit hard to tell. Lets get some real checks going next.

