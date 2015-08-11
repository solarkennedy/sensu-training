## Tinkering With Uchiwa

Welcome to "Tinkering with Uchiwa". If you are installing Sensu for the first
time, then this dashboard will be new to you, so I want to show you around
a bit.

As a reminder, Uchiwa is the open source dashboard. There is the enterprise
dashboard too, but it operates very much in the same way.

### Make Some Events

    wget https://raw.githubusercontent.com/solarkennedy/sensu-shell-helper/master/sensu-shell-helper
    chmod +x sensu-shell-helper 
    ./sensu-shell-helper  -n "check_http" /bin/false
    ./sensu-shell-helper  -n "check_ssh" /bin/false
    ./sensu-shell-helper  -n "check_ssh" -j '"source": "some-other-host1",' -- /bin/false
    ./sensu-shell-helper  -n "check_snmp" -j '"source": "some-other-host2",' -- /bin/false

Do you notice anything in particular about this first view? It is a little
tricky, how about what you *don't* notice?

This might surprise you, and this is another very common misconception about
Sensu that people have, especially coming from other monitoring systems. Sensu
is not a "green light" dashboard.

Green-light dashboards don't scale very well. If you have 1000 sensu clients
each with 1000 checks that are all green, that is 1 million events that sensu
and the dashboard would have to process.

Sensu's event-driven architecture means that it only shows things that are red.
This is a good thing, hopefully you can just get used to it.

While it is true that sensu can record the event output of green checks, by default it does not: You only see the things that are failing.

#### More Events Page

Lets talk about the columns on this page.

Why the "Source" column? Why not "hostname"? Although this is and advanced topic,
Sensu can get alerts for hosts that don't really exist. This is for things like
switches or clusters or things like that. I've made some fake hosts here for
demonstration purposes.

Check is the check name. Output would be the last outout of the check, for these injected events I didn't add any output data, but this would be where it would say "Critical, only 100M free mem" or whatever"

This "Occurences" column represents how many times this event has fired. It doesn't
count how many times it has been green.

This cloudy thing is "datacenter", remember that uchiwa references each different
Sensu cluster as a datacenter, so this would allow you to easily sort by datacenter
if you wanted to. And this "issued" column, this represents how long ago the
event came in.

Lets click on an event to get more data.

#### An Event

You can see in this modal we have some more data about the host that made it and the event output. This is mostly informational, lets talk about the buttons you can click on.

These speaker icons are for silencing the host over here, or the check over here.
If you silence a host, most Sensu handlers will also suppress notifications
for other checks on that host as well. You can also silence the check as well.
If you silence something, it won't make alerts, as you might expect.

One subtle thing to note here is that the handlers that sensu executs have to be
"silence-aware", our simple cat handler is going to continue to operate and
doesn't know anything about silences.

How about this X? What does it mean to "delete" a client? I'll talk about that in a bit on the clients page. How about this Checkmark? You can click this checkmark to
manually resolve the check, as if it was just fine. Granted, if the thing that 
spawned the alert alerts again, it will come right back of course. But remember
that in Sensu everything is event driven. Maybe this was a one-time event?
Maybe there is no such thing as check_snmp anymore and it will never resolve
by itself? It happens sometimes that you have to manually resolve things.


### Clients

You can see the client here. Sensu *does* track the status of the clients.

You can Silence a client if you don't want it to make any noise from the
handlers by clicking this volume icon. Again, this *will* silence all the checks and
the client itself. Which is what most people see as the expected behavior.

If you click on a client, you can see more data. This is very similar to the
check modal, except here sensu shows you all of the checks it knows about.

They are green, but this listing is not necissarily exhaustive or fresh.
It just represents checks that it has a history for, and if the last
return code for the history of a check is 0, then it shows up as green here.

#### Delete a client

Lets go ahead and delete this client. What happened? I thought I deleted it?
Well deleting it *did* auto-resolve any of the failing checks it had before.
But the sensu client running our our host auto-re-registered itself within
a few seconds! Remmeber Sensu does not have some big master list of hosts
and checks that belong to them. It operates on events, and this host
just decided to register itself now.

Hopefully this is getting the gears turning for you on how useful this would
be in a dynamic environment. Remember all of this is happening through a
an api. And there are also good command line tools. Just think about what
you can build when you work with a system that doesn't have to be "told"
that a host exists, and it can just come into existance!

But you saw that me deleting the client didn't make it go away. Remember
my metaphor about the map and the territory? Sensu is always in a constant
state of reconstructing its map to match the territory.

### Checks

Checks will show *only* server-side checks. The Sensu-API is not aware of
standalone checks that are only defined on the clients. This can also be
confusing to newcomers, because they expect to see every check ever here.

But, if you are running a Sensu-client on the same host as the Sensu Server,
then you will see those checks here.

This screen is mostly read only, to give you an idea of the Subscription
based checks and who subscribes to them.

### Stashes

Stashes are Sensu's kinda free-form key-value store. Sensu handlers use the
slience stashes to mark a host or check as silenced. But they can be anything!
This makes Sensu very flexible, but taking advantage of this feature is a
little outside the scope of this video.

The important thing to know is that Silences are implemented by making a stash
here. And in this view you can see all the stashes.

Lets silence a few things and see how they show up here.

Stashes are just keys and values. You can use them for anything, but silencing
is the most popular way to use them. Plus remember they have an api.
What if you have a provisioning system that launches new hosts and you want them
silenced for a few hours? Can you imaging making that api call or using
the cli tool in a script? With the reason field being "The host was newly
provisioned" and the "source" was "your provisioning tool"? Could be pretty cool.


### Aggregates

Aggregates are an advanced topic, they have to do with executing a check over
the course of many hosts and doing a tally or aggregate of the results and
acting on it.

I'm not going to talk about it in this introductory course, but I'll link to
it in the external resources section of this lecture.

### Datacenter

Here is where we see that multi-site capability show up. We only defined one
site, and it shows up here. If you were building a multi-site setup, the health
of the individual endpoints would show up here.

## Conclusion

That is about it for the dashboard. Uchiwa is a modern dashboard. It is pretty
responsive and gets the job done.

This is just an introductory course, but you can do a lot more. Uchiwa will actually automatically embed links and images, which can give you a really rich experience if you want to embed graphs from an external datasource.

And of course, remember the API. The dashboard is just one way to visualize events. On my github I have a script that interacts with the API and prints a list of
events in the message of the day, so you see it when you log in.
