# Pushing Your Own External Check Results

Pushing your own external check results to the Sensu client is and advanced
topic, that I was going to reserve for a future course, but I figured I would
at least give a mini-lecture on how to use this feature.

The official Sensu documentation does a pretty good job at explaining
what this does, and gives and example:

    https://sensuapp.org/docs/latest/clients#client-socket-input

But I think it could use some elaboration.

## What are these checks and where do they come from?

Let's review how normal checks actually end up processed by the Sensu
infrastructure. Remember that Sensu checks can be either subscription based,
which means the Sensu-server schedules them, or they can be standalone, where
the Sensu-client schedules them.  Regardless, the actual check is executed by
the Sensu-client, and then the Sensu-client takes the result of the check, call
it "event data", and then puts it on the queue, and then the Sensu server picks
up on it for processeing. From there the Sensu server might invoke some
handlers, send you an email, whatever.

Now, imagine if there was some way to just "inject" event data like that, but
without needing the sensu-server or sensu-client to actually execute the check.
That is what this external result input is. It is where something *else* does the
actual check execution, and just relays the resulting event data. Think of it as
a kind of bypass, where the Sensu client gives you away to deposit your own custom
result data onto the queue, even if that event data isn't even "from" the local
Sensu client.

## Where would this be useful?

Where would this be useful? It is useful in situations where you have something
you want to check that you won't want to have to pre-configure the Sensu-client
to be aware of it. Let's look at one of my favorite use cases for this: Cron jobs.

Let's say we have a cron job in place that we want to monitor, like this

    crontab -l
    * * * 0 0 send-nightly-customer-report

So we have this nightly customer report, and I would like to know if it doesn't work.
Sure, you could check your inbox for cron emails. Or maybe you could edit your
script to touch a file or something, and then configure Sensu to watch the
modification date of that file, but I have a better idea.

We can use the fact that Sensu allows us to push arbitary event data onto the
queue, by pushing our own event data for this report. And in that event data,
we'll push a status code of 0, meaning "OK", when it works, and a "2", for
CRITICAL, when it doesn't work. But that means we need to adjust are script
or something to make it talk to RabbitMQ right? Wrong.

First, we don't have to talk to RabbitMQ or anything like that. We can talk directly
to the local socket, which is listening on localhost port 3030. It isn't even
HTTP, it is just a tcp socket that accepts plain text JSON. This interface is so
simple, you could write a bash script to use it.

So I did:

    https://github.com/solarkennedy/sensu-shell-helper/

This is a bash script that I use, to help make it even easier to send these
events to the local socket. All you have to do is prepend your command with
`sensu-shell-helper`, and you will get an event after your script runs.

Let's try it out and see how it works behind the scense. First I'll download it:

    wget -O /usr/local/bin/sensu-shell-helper https://github.com/solarkennedy/sensu-shell-helper/raw/master/sensu-shell-helper
    chmod +x /usr/local/bin/sensu-shell-helper

And now let's make up our fake report

    vim /usr/local/bin/nightly-customer-report
    #!/bin/bash
    echo "Sales are great! Everything is fine!"
    exit 0
    chmod +x /usr/local/bin/nightly-customer-report

Now we can prepend our command with `sensu-shell-helper`:

    sensu-shell-helper nightly-customer-report

That's it! If the nightly-customer-report script starts failing, we will
get a sensu alert. What would that alert look like? We'll let's simulate
a failure with our script

    vim /usr/local/bin/nightly-customer-report
    echo "But the script didn't work for some reason!!!"
    exit 1

Now let's run the command, with the `-d` option for a dry-run:

    sensu-shell-helper -d nightly-customer-report

Now you can see the actual JSON event data that would have been sent to Sensu.
It has the name of this check: nightly-customer-report, and it even gives us the
output, and the status code is 2, meaning it is CRITICAL. By default the
sensu-shell-helper interprets any non-zero return code from the script as a
critical failure.

Let's run this thing and see what it looks like using the sensu-cli tool:

    sensu-shell-helper nightly-customer-report
    sensu-cli event list

Now you can see that the event is there. Now let's "fix the script" and do it again,
simulating what it would be like when cron runs it the next time:

    vim /usr/local/bin/nightly-customer-report
    dd
    exit 0

And now let's run it again...

    sensu-shell-helper nightly-customer-report
    sensu-cli event list

Now you can see the event is gone, and we would have gotten a resolve email,
saying that everything worked ok this time around.

So the sensu-shell-helper is just one example of a quick tool that takes advantage
of this local-socket feature, and allows you to make Sensu alerts for any command
line invocation of anything, not just cron jobs of course.

But you see, I didn't define *any* checks on the Sensu client, or on the sensu-server.
No daemons were reloaded, no check config files were put on disk. The check for the
nightly-customer-report came and went freely, the Sensu server didn't care that it
came from the localhost socket and not from the Sensu-client itself. It processes
the event just the same.

## Another Example: External Devices

Once you can send arbitrary events, you can do even more interesting things. This
is extra useful when the things that you are checking are very dynamic. 

Let's build off our customer example, but this time let's say we want to send an event
on a per-client basis. And this time, I don't actually want to use the shell-helper,
I'm going to use the standard sensu-cli command.

First let's setup the customer report script:

```bash
#!/bin/bash
#
# Iterates through each client and will alert or resolve based on
# whether action is required.
#

function check_customer {
  customer=$1
  standing=$2
  # If a customer is in bad standing, send an alert so someone
  # can look at it and try to fix it
  if [[ $standing == "good" ]]; then
    sensu-cli socket create --name "$customer" --output "Ok: Customer $customer is fine and is in in $standing standing" --status 0
  else
    sensu-cli socket create --name "$customer" --output "Critical: Customer $customer is in $standing standing. Take action!" --status 2
  fi
}

# Iterate over all the customers
check_customer "customerA" "good"
check_customer "customerB" "bad"
check_customer "customerC" "good"
```

Obviously this silly little bash script just serves as example. Hopefully
real people are not writing their customer reports in bash.

But you can see that this script iterates over customers and our `check_customer`
function will send an event for that customer. It is important that we send
and event when something is wrong, but we also want to send a "good" event
when everything is ok, so we get that "resolve" email when things are fixed.

Let's run this thing and see what happens:

    nightly-customer-report

If that worked, then it would have send an "ok" event for customers A and C, and a "critical" event
for customer B. Let's see what events are now out there:

    sensu-cli event list

And now let's put customerB in good sanding and see if the event goes away:

    vim /usr/local/bin/nightly-customer-report
    /bad/good/
    nightly-customer-report

And now do we have any events?

    sensu-cli event list

And it resolved.

## Conclusion

Obviously this is just an example, hopefully no one is writing customer reports
in bash. But it just serves as an example of how you can use this external
event data feature of sensu to push your own events, for things that come and
go like cron jobs and customers, without having to "let sensu know" beforehand
that it exists.

Before we conclude I would like to give a couple more examples of how this
feature can be used.

    https://github.com/solarkennedy/sensu-shell-helper/

We saw how my `sensu-shell-helper` can be used to
monitor the output of any command line invocation, like in a cron job.

In this `check-serverspec.rb` example:

    https://github.com/sensu/sensu-community-plugins/blob/master/plugins/serverspec/check-serverspec.rb

The script iterates over a bunch of serverspec tests, and then emits and event
for *each* test, whether it was a pass or a fail.

In this example:

    http://gist.leavesongs.com/countryHick/26a3dd2824b86dd5f994

Someone has written a script that loops over some special SNMP traps and
emits custom events based on teh name of the trap.

In this example:

    https://gist.github.com/joemiller/5806570

The script inspects the Pantheon API, enumerates over all the endpoints,
and pings each one, and emits and event for *each* endpoint.

I hope that better illuminates what this feature can do for you. It is certainly
an advanced feature. You can get by with normal Sensu checks for a long time
before you encounter a case where you need this kind of custom event creation.

But when you do have this tool in your toolbox, it means that when you encounter
such a situation, where you don't know beforehand what it is that you need to
monitor exactly, and you need to have a custom event based on what is out there,
this feature can be a very powerful tool, and can help you monitor things that
are inherently dynamic.
