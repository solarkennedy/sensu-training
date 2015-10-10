# Standalone, Safemode, and Subscriptions

When running Sensu in production, you need to be aware of how
Sensu schedules checks. The ideas of "standalone checks",
"subscription checks", and "safemode" are all related ideas that
I think are very important, and worth devoting a small lecture to
explain what they mean.

Let's go to the whiteboard to explain...

## Sensu's Scheduling Model

In order to talk about how Sensu's check scheduling model works, we have
to talk about RabbitMQ. If you have a Sensu client and a Sensu server, RabbitMQ
is the *only* method of communication between the two, that is it.

But you have to remember that RabbitMQ is a two-way street here. Not only can
Sensu clients put check results onto the queue for processing, but the Sensu
server can also put check requests onto the queue for clients to act on.

Your Sensu configuration and your check configuration will determine how this
behaves exactly.

## Subscription Checks

Let's talk about "Subscription" checks first. Subscription checks are checks
that are scheduled by the Sensu Server. In order for them to work, you need at
least two pieces of configuration in place. This will be more obvious with an
example.

Let's say you have a Sensu server and a bunch of Sensu clients running
on your cluster of webservers. To setup a subscription-based check for
something like `check_http`, you need the actual check defined on the
Sensu server. It will have a flag for which subscribers should run this check,
you might say "webserver" need to subscribe to it. Once this is in place, on
the regular schedule, the Sensu server will begin to put out check requests
onto RabbitMQ, calling our for anything subscribed to "webserver" to execute
this check.

But who is listening? Any server client that has been setup with "webserver" in
the client subscriptions configuration will be listening for these check
requests. When the server puts out that call for `check_http`, the clients that
are subscribed will pick up on it, execute the check, and put the results back
onto the queue for the server to process. The advantage to this model is that
you have central configuration and control over the checks, you only have one
place where this check is defined, and conceptually it is similar to how most
monitoring systems work, more or less. In a sense the Sensu clients are kinda
acting like just "dumb" agents that are executing checks on the host, for the
server. 

### Security Implications / `safe_mode`

Now if you are like me, with a decent amount of sysadmin experience, your first
reaction to this might be, "wait, the Sensu clients just do whatever the server
tells them to do? This sounds like a "remote execution exploit as a service"
setup.

And it is true, anyone with access to RabbitMQ in this setup could ask the
Sensu clients to do anything, really. Granted processes are spawned under the
Sensu user, it still seems like a pretty relaxed security model. Personally, I
would not run Sensu like this in a production setup, without what is called:
"`safe_mode`".

With `safe_mode` on, Sensu clients will refuse to run any check that has not
already been defined in their local configuration. This is certainly a little
safer, but now it means that you must pre-configure your clients with the
checks that they are going to run. That means now they each have to have
a file with the `check_http` check defined on them.

If you ask me this should be the default, but I understand why it is not: out
of the box it restricts how useful Sensu is in this subscription mode. But this
is certainly something engineers need to be aware of when they are integrating
Sensu with their infrastructure.

I personally don't see a problem with requiring a config file with this check
definition, do you know why? It is because I use configuration management! If
you haven't watched any of the lectures on using configuration management tools
with Sensu, I encourage you to do so. If you are using configuration management
to deploy Sensu and setup the list of subscriptions, then it isn't that big of
a deal for the configuration management tool to also deploy the config file for
the `check_http` check at the same time. After all, that is really what
configuration management tools do best.

## Standalone Checks

But there is another option: standalone checks. Standalone checks are defined
on the client *only*. Also the client is responsible for actually scheduling
this check on itself. In fact, even if the Sensu server is down, standalone
checks will continue to run on their intervals, because it is the job of the
Sensu client.

You can define a standalone `check_http` check on any server, regardless of
it's subscriptions, and the Sensu client will see it, schedule and execute it,
and that is it. The nice thing about this setup is that no configuration on the
Sensu server is needed at all. Any client with standalone checks just operate
on their own, and the Sensu server just operates on the results of those
checks.

The downside is that now you must deploy this configuration file to every
webserver, you can no longer centrally control it. Again though, this is
exactly what configuration management is for. If configuration management is
setting up your webservers, it can deploy this Sensu config file too. In this
world, `safe_mode` doesn't apply. You should certainly turn it on, but it
doesn't affect the behavior of standalone checks.

As I've said before, I like standalone checks myself, I think they are actually
easier to understand than subscription checks, and I like how easily they fit
with the configuration management model. If you are using configuration
management to deploy a webserver on a particular port, and you wanted to change
that port, the configuration management tool could change the port of the
webserver and update the monitoring configuration on the same host, using
standalone checks, and that is it.

With the subscription model you might update your webservers, but then you have
to update the Sensu server too. But what if the rollout is slow? Well in the
standalone world, the app and the monitoring config are on the same server, so
they can change kinda atomically together. I think this is cool. You could do
this with subscriptions as long as you had the check defined on the server
already, and the local settings will override the check definition that the
server sends out, but at that point it seems like you might as well just do a
standalone check.

## Aggregate Notes. 

I should note that there is an advanced Sensu topic called "aggregates". Aggregates
are a way for the Sensu server to schedule a check across a set of subscribers and then
tally the results to give you a kind of "aggregate" view. Aggregates don't work on
standalone checks because they are not centrally scheduled.

## Conclusion

So in conclusion, "subscription" checks are defined and scheduled on the
server, and then clients that are tagged with the same subscription pick them
up, execute the check, and then put the results back on the queue.

With `safe_mode` on, these clients will only execute those checks if the check is
also defined locally, for safety.

"standalone" checks are checks that are defined locally on the client-only,
they don't need any server-side configuration. `safe_mode` doesn't affect them.

I hope this makes this topic very clear. It is an idea unique to Sensu's
architecture, so I thought it was worth clarification. If you are using
configuration management, I find that standalone checks work well for that. If
you are setting up checks by hand, subscription checks are easy with
`safe_mode` off, but you do need to be aware of the security implications.

Like always, I'll have additional documentation on these topics as well as show
notes in the external resources section of this lecture.
