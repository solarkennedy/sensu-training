## Adding a Real Check

### Intro

So far we have been using just been using the toy check-mem from the
tutorial on the official documentation. Let's see if we can do something
more realistic and useful.

### Going for a Nagios Plugin

You know, not everybody has the luxury of setting up a greenfield monitoring
system. Let's say that you are migrating from Nagios and you want to re-use
your existing check definitions and plugins.

I think this is great. I love re-using components. Let's get them

    sudo apt-get -y install nagios-plugins-basic

Now we have those familiar nagios checks:

    dpkg -L nagios-plugins-basic | grep check_

Let's use the good ole-fashion `check_disk`.

    /usr/lib/nagios/plugins/check_disk /

Just for fun I'm going to make a "ballast" file that we can delete to clear the
alert.

    dd if=/dev/zero of=ballast bs=1024 count=1024000

Let's crank it till it fails

    /usr/lib/nagios/plugins/check_disk /

Now let's look at how we might use thing and configure it.

### Configiguration

    cd /etc/sensu/conf.d/

We can peak at the other example check definition, or we can make our own.
We can decide if this is going to be a standalone check or a subscription
check. Remember that standalone checks are defined and scheduled by the
client. Subscription checks are defined and scheduled on the server.

I like standalone checks myself. And disks are one of those things that
are intrinsic to the server, sorta. So let's pretend that we are going
to deploy these checks with configuration management, a provisioning tool,
or something like that.

    sudo vim check_slash.json

Sensu configuration files are JSON, and they are dictionaries of
whatever the thing is you are defining. This is a check so it looks like this:

    {
      "checks": {}
    }

Now inside this dictionary we can define our check:

    {
      "checks": {
        "check_slash": {
          "command": "/usr/lib/nagios/plugins/check_disk -c 50% /",
          "interval": 10,
          "standalone": true,
        }
      }
    }

Not that bad. The `check_disk` in command we came up with kinda experimentally
but in real life you might copy+paste from an existing setup. Sensu checks
are always executed by the client, so there is no need for an extra
remote execution program. The Sensu user has permission to run this command,
so we don't need sudo.

Interval is how many seconds between checks. So this check will run once per
minute. With Sensu, because all the checks are executed by the client, it is
relativly cheap to have quick execution times. And `standalone: true` because
this is a check scheduled and defined by the client, the Sensu server doesn't
know about it.

So we save the file, let's verify it is valid syntactically:

    jq . check_slash.json

Now we only need to restart the sensu client to pick up on it, because it
is a standalone check.

    sudo /etc/init.d/sensu-client restart
    tail -f /var/log/sensu-client.log

Seems to be working, our sensu-client is executing this check every 10 seconds.
It is currently failing. Check our mail?

    sudo mail

Now lets clear our ballast file to free up some disk space.

    rm ballast

Now check our mail?

    sudo mail

## Installing Community Plugin

Now let's say that you were not content with the old fashion plugins
and you would like to try something new out of the community plugins
repo. You see something that catches you eye and you say, "oh I really
want some rabbitmq checks", so you go look for them, and
you find some good ones!

Great! By all means take advantage of the existing work that has been
open-sourced for you to use! Now remember how to install this using
the embedded ruby:

    sudo /opt/sensu/embedded/bin/gem install sensu-plugins-rabbitmq

Now where did it put the scripts:

    ls /opt/sensu/embedded/bin/ | grep rabbit

Does it work?

    /opt/sensu/embedded/bin/check-rabbitmq-alive.rb

Amazing. As long as you use the full path to this thing, you don't have to
mess with any environment variables or anything, the embedded ruby
is self-contained and the script already has the full path to the correct
ruby interpreter in the she-bang line like we saw before.

Lets setup the check:

    {
      "checks": {
        "check_rabbitmq_alive": {
          "command": "/opt/sensu/embedded/bin/check-rabbitmq-alive.rb",
          "interval": 10,
          "standalone": true,
        }
      }
    }

And restart the sensu client

    sudo /etc/init.d/sensu-client

Now what will *actually* happen when I stop rabbitmq?

    sudo /etc/init.d/rabbitmq stop
    tail -f /var/log/sensu/sensu-client.log

The sensu client cannot talk to RabbitMQ, and therefore can't report
that RabbitMQ is down. This is kind a strange situation. In later courses
I'll discuss how to monitor Sensu itself as a whole, but with RabbitMQ down,
the Sensu client cannot operate.

    sudo /etc/init.d/rabbitmq start
    tail -f /var/log/sensu/sensu-client.log

And you can see that the Sensu client automatically reconnects and begins operating again, but the Sensu server never got a message that RabbitMQ was down.

But what notifications *did* we get while RabbitMQ was stopped?

    sudo mail

The Sensu client periodically sends keepalive heartbeats via RabbitMQ for the
Sensu server to pick up on. When RabbitMQ was down, the Sensu-client was not
able to send its heartbeats, and the Sensu-server picked up on that, and alerted
us. It does not mean that the Sensu-server couldn't talk to the client, at least
not directly.

Anyway, that was just a small diversion for installing checks. We covered using
existing nagios plugins and modern Sensu Community Plugins from Github. Feel
free to review the external resources of this lecture to see the official
documentation on Sensu check definitions, as well as all the commands I typed
in this lecture.

### Further Reading

* https://sensuapp.org/docs/0.20/checks

