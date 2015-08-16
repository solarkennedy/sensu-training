# Installing a Real Handler

## Intro

If you remember from the architecture lecture, the job of the Sensu Server is to
respond to event data and act on it. The actions are usually in the form of
"Handlers".

A Sensu "Handler" is a script that does something based on the event data that
comes from standard in. This makes them pretty easy to write, test, and
understand.

Remember our "cat" handler?

    cat /etc/sensu/conf.d/handlers.json

It is pretty naive, and just spits out the event data right back at us. You can
see it in the logs:

    tail -f /var/log/sensu/sensu-server.log

Handler output goes in the sensu-server log, because that is the thing that is
executing handlers.

## Exploring Community Handlers

Lets go find a handler to send us some email. Sending email is probably the
most popular thing to do with monitoring systems. Where should we go?

Well you should be aware of this sensu-plugins github project:

    xdg-open https://github.com/sensu-plugins/

This github project hosts lots and lots of Sensu Plugins. A Sensu plugin
is just a general term for anything that Sensu runs. Handlers are one
kind of Sensu plugin, but there also checks and other things.

Well, lets type in the search box for mail...

sensu-plugins-mailer sounds legit. sensu-plugins-qmail is probably plugins
for checking qmail, not sending email. Sensu-plugins-ponymailer is a more
advanced email handler using the "pony" rubygem. Lets start with the first
one: sensu-plugins-mailer

Lets see.. some require configuration, some example json. So it Sends some
email, probably what we want. Now what?

## Installation

This is a ruby gem, so to install it you use the gem command. These are just
general docs, nothing mailer specific. If you already know how to handle
rubygems, you may be right at home. Not everybody does though. Does this
mean you have to install ruby to send email?

Well, remember earlier on when I talked about how Sensu was packaged?
Remember that it is an omnibus package, meaning it comes with its own
version or ruby with it!

This is pretty convenient. We don't have to install another ruby, who
knows what version of ruby it would be or whatever. If we can just use
Sensu's ruby, lets do that. Where is it again?

    ls /opt/sensu/embedded/bin/

The gem command is right there. Will it work?

    /opt/sensu/embedded/bin/gem install

And what do we want to install? Not disk checks...

    /opt/sensu/embedded/bin/gem install sensu-plugins-mailer

Didn't work. Don't have permission. That is because this is still a system package
and it is all owned by root, so you have to sudo:

    sudo /opt/sensu/embedded/bin/gem install sensu-plugins-mailer

Ok still didn't work. Missing gcc?

    sudo apt-get install build-essential
    sudo /opt/sensu/embedded/bin/gem install sensu-plugins-mailer

But where did it put it?

    /opt/sensu/embedded/bin/gem contents sensu-plugins-mailer

Ok, so it is installed in the gems folder in the embedded ruby stuff. Ok.
But what about the binaries?

   ls /opt/sensu/embedded/bin/ | grep mailer

And checkout the shebang:

    head /opt/sensu/embedded/bin/handler-mailer.rb 

This is important because we don't want this handler using the system
ruby, if we even have any. Does it work?

    /opt/sensu/embedded/bin/handler-mailer.rb

Is it working? No news is good news? Watch I'll press cntrl-d.

    error reading event: A JSON text must at least contain two octets!

See, this is what handlers do, they wait for event data in json form to come in
to stdin. So it is working. Lets configure it.

    cd /etc/sensu/conf.d
    sudo vim default_handler.json

You can see the leftover cat handler here. Lets just replace the path.

Now what about configuration for the handler? Lets check back at the docs:

    {
      "mailer": {
        "admin_gui": "http://admin.example.com:8080/",
        "mail_from": "sensu@example.com",
        "mail_to": "monitor@example.com",
        "smtp_address": "smtp.example.org",
        "smtp_port": "25",
        "smtp_domain": "example.org"
      }
    }

It doesn't say what file this goes in right? Well Sensu just does
a big merge of the json dictionaries in this thing, so it actually
doesn't matter what file it goes in. I like to have the handler
and config in close by, so lets just stick it in the same file

    "mailer": {
      "admin_gui": "http://localhost:3000/",
      "mail_from": "sensu@localhost",
      "mail_to": "root",
      "smtp_address": "localhost",
      "smtp_port": "25",
      "smtp_domain": "localhost"
    }

So we changed a config file. Do we need to do anything else?
Yes, we do need to restart the sensu-server. Remember that handlers
are executed and configured by the sensu server, so in this case
it is the only thing that needs to be restarted:

    sudo /etc/init.d/sensu-server restart

Now lets watch it:

    tail -f /var/log/sensu/sensu-server.log

Is it working? Try to think back about the uchiwa lecture and think
to yourself, why don't I see anything about email? Of course, Sensu
is not a green light dashboard. And it is anything actually failing?
Cause if there isn't anything failing, no events are going to get
processed and no handlers are going to fire. This seems a little obvious
in retrospect. Lets make our check fail.

    sudo vim check_memory.json

Now, do I restart the sensu server or the sensu client? Or what?

Well this particular check is a subscription check, which is defined and published
by the server, so you should restart the sensu server

    sudo /etc/init.d/sensu-server restart

Lets watch how the client reacts:

    tail -f /var/log/sensu/sensu-client.log
    {"timestamp":"2015-08-15T22:36:00.230324+0000","level":"info","message":"received check request","check":{"name":"memory","issued":1439678160,"command":"exit 2"}}
    {"timestamp":"2015-08-15T22:36:00.238223+0000","level":"info","message":"publishing check result","payload":{"client":"mycoolhost","check":{"name":"memory","issued":1439678160,"command":"/etc/sensu/plugins/check-mem.sh -w 128 -c 64","interval":10,"subscribers":["test"],"executed":1439678160,"duration":0.008,"output":"MEM OK - free system memory: 296 MB\n","status":0}}}
    
Why is this happening? The server *is* telling it to run a particular command,
but the client uses its local version of check-mem. Whats up wit that?

This behavior is surprising, but an artifact of the fact that we have
the sensu server and sensu client on the same server. If the Sensu client
sees a check definition, it will assume that the check definition contains
special overrides that are designed to take precedence over the generic
check-mem that comes from the server. For example, you can imaging you
have a fleet of servers that have different memory capacities, and
on a special server with lots of ram you set a different threshold
for how much ram is critical. That is what is happening to our example
here.  The solution is to restart the sensu client.

    sudo /etc/init.d/sensu-client restart
    tail -f /var/log/sensu/sensu-client.log

This is one of the reasons why I personally prefer client-defined checks
*only*. I trade the centralized control in favor of having each client
responsible for their own checks. This is easier to do with configuration
management, like Puppet or Chef.

Anyway, is it working now? Are we getting emails?

    tail -f /var/log/sensu/sensu-server.log

Its doing "something" Lets look at the logs really carefully:

    {"timestamp":"2015-08-15T22:43:20.244902+0000","level":"info","message":"processing event","event":{"id":"185a9dbe-c132-4aae-9cef-4733c988d30b","client":{"name":"mycoolhost","address":"localhost","subscriptions":["test"],"version":"0.20.2","timestamp":1439678580},"check":{"command":"exit 2","interval":10,"subscribers":["test"],"name":"memory","issued":1439678600,"executed":1439678600,"duration":0.004,"output":"","status":2,"history":["0","0","2","2","2","2","2","2","2","2","2","2","2","2","2","2","2","2","2","2","2"],"total_state_change":4},"occurrences":19,"action":"create","timestamp":1439678600}}
    {"timestamp":"2015-08-15T22:43:20.760092+0000","level":"info","message":"pruning check result aggregations"}
    {"timestamp":"2015-08-15T22:43:20.908157+0000","level":"info","message":"handler output","handler":{"type":"pipe","command":"/opt/sensu/embedded/bin/handler-mailer.rb","name":"default"},"output":["only handling every 180 occurrences: mycoolhost/memory\n"]}
    
It is getting an event. But the handler is doing this, "only handling..."
What does this mean? Well occurrences is how many times the event has
occurred. You can see how many occurrences we have had here. (19).
And by default this handler only does something every 180 occurrences.
This is a filter mechanism so you don't get an email every 30 seconds.

There are lots of things you can do to tune this filter, but they are out
of scope for this introductory course. For now you should just be aware
of them and know that they will suppress handler activity.

This check was already failing 19 times before we event restarted the
server, so we are going to have to wait before this handler is activated...

You know what we can do though. We can use Uchiwa to manually resolve this check
which will reset the occurrences back to zero, as if it was fresh.

And now we made it do something. A little messy here, but connection refused?
Thats because on this vagrant box I don't have a mail server running to use.
Let me install one real quick.

    sudo apt-get install postfix mailutils

And now a manual resolve....

And now the handler says it did something:

    "output":["mail -- sent alert for mycoolhost/memory to root\n"]}

Lets read it:

    sudo mail

It works! We got an email from that manual resolve and from the alert.

Obviously we have just scratched the surface here, but at least you have
a Sensu installation that can email you, which is not bad.

There are many more things you can do here, there are tons of community
handlers available out there, and of course you can write your own. Remember
that handlers are just scripts that take in the event data from stdin and
then do something.

Check the external resources section of this lecture for show notes and links
to the documentation on handlers, as well as all the commands I used in this
lecture.
