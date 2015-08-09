## Why Should I Care About Sensu?

So you know a bit more about how Sensu works now under the hood.

Lets talk a little bit about why you should even care about investing your time
with a different monitoring system. Believe it or not I do want to respect your
time and money, and I don't want you to waste your time on a tool that isn't
right for you.

On the other hand, I think that all engineers should always be on the lookout
for ways to improve their craft and expanding their toolbox with new and
better ways to do things, and I think Sensu is a pretty good tool.

### Traditional monitoring

In order to really talk about why Sensu is worth looking at, lets go back to our
whiteboard and talk a bit about how "normal" monitoring systems work. I'm mostly
going to be thinking about Nagios in my head, because I have lots of experience
with it, but most traditional monitoring systems work in the same ways.

A traditional monitoring system works like this, you have a central monitoring
server, and it is programmed with a list of things to check.

    Checklist:
    check A
    check B
    check C

And your servers might be A, B, and C. So it checks them. Simple, gets the job
done. But what was the job? Sure part of the job was making sure that your
servers are up, but what about everything else? Checking disk space, or
that a thing is running. The limitations of this kind of system becomes
apparent right away, because from the outside you can't see in.

The solution to most traditional monitoring systems is an agent. The agent runs
on the remote server and does things for the central system. In nagios this is
nrpe, or `check_by_ssh`. In my experience, this quickly leads to lots and lots
of remote execution checks. Mostly because it is on the server itself were
you can do the best introspection. And the agents turn into mostly remote
code execution as a service, that is what they are designed to do after all.

### A Step Back

This may seem perfectly normal for you, but ask yourself, why do we need remote
code execution in the first place? Well the reason is due to the architecture.
It was *designed* this way, so it is hard to change. But, *do* you need a
big-brother with a central config telling all the agents what to check and
when to check it? What if checks were scheduled *on the client* in the first
place, and just ran there anyway? Thats what sensu does. It can be used in the
central way, but I think it really shines when the clients take responsibility
for their own checks.

So, think about why the centralized way is a limitation. What happens when that
central server gets overloaded? If a rack of servers goes down, and now it has to
iterate over the failing things more quickly, what happens to the check latency?
With Sensu, each client can be made responsible for its own checks. Your checks
are timely and can scale with your clients, not the server. Thats nice.

### Client-side Config

Lets looks at this difference in architecture from a different perspective:
configs. On the traditional monitoring systems the configuration is of course
centralized. But then when you want to run things on the hosts, you need to
*also* configure the remote agent with some extra configuration, and keep it
in sync. With Sensu, client-side checks are defined on the client, which
means that you can deploy them *with* your server.

How about we think about it in a different way. Imagine all your servers our
there in your environment. Call this "the territory". You've got web servers
or file servers or whatever out there. Most monitoring systems require *you*
as an engineer, to keep the configuration of the monitoring system up to date,
lets call this the map. How close do you think your map matches up with
the territory out there. How does your map stay in sync? Is it by manpower?
By a computer program?

With client-side configuration, you can deploy your monitoring *with* your
application. You can make it so the map and territory are in sync by design,
and its great. This means you can build systems that require no human
intervention to keep up to date. There is a lot more room for automation
with Sensu by design.

### New Hosts

Lets talk about how new hosts get added to monitoring systems. On a traditional
centralized monitoring system that usually means that it needs to be configured
of course. That might mean adding a new host in a config file, or via a
detection mechanism, or maybe through some sort of wizard.

What if I told you that Sensu has no such construct? The Sensu server starts
responding to events from Sensu clients as soon as they send their first
event, and can be removed with either automatically or by an API call. Again,
lots of room to build much more flexible systems that can grow and shrink,
something that would be very difficult to design with a traditional monitoring
system.

### New Checks

Likewise, think about the barrier to adding new things to check in traditional
monitoring systems. It might include a config file or clicking on something on
an interface or expanding some sort of template.

With Sensu you can have the checks defined on the server or client, thats fine.
Yes, you can deploy your checks with your applications, through whatever means
you have.

Ready for the next mind-blowing idea? Sensu can schedule and execute checks,
but it will also will respond to events that *you* create. That means you can
take any kind of list of things to check, maybe an API, or an internal list
of clients, or tweets, or whatever, and generate events on them, and have
the Sensu server act on them as if they had been pre-configured and scheduled
the whole time.

This concept is a little hard to explain without some real world examples, but
I cover this in more advanced courses. The point is that if you have a list of
services from your PaaS, or a list of external endpoints to check, or a list of
sites that you need to iterate over, you can generate your own kind of meta-check
that acts as if someone was dynamically adding these checks on your behalf
into Sensu, and the Sensu server doesn't care, it just acts on the events normally.
Pretty far out.

## Conclusion

Sensu's client-side architecture is just a better design in a world of deployed
applications, configuration management, and elastic compute. There is just
so much more room for automation with it, where as with centralized monitoring
systems, it is just cumbersome. In fact, Sensu is so flexible that it doesn't
even need any checks defined! If you wanted to you, you emit all your events
yourself in json form and let the Sensu infrastructure take care of the rest.
This is an extremely powerful idea and empowers engineers like you to build
really interesting and elegant monitoring systems.

I hope this gives you a better idea around "why" Sensu works like this. Again it
will be a little hard to really understand all this without seeing things
in action, but of course that is what this course is for! I hope to show you
Sensu in-action in front of you, which will hopefully give you an understanding
that is deeper than what you would have from just reading the docs.
