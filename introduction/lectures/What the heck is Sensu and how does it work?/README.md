## What the heck is Sensu and how does it work?

### Intro

Welcome to Sensu: an Introduction. Throughout this course I will be teaching you the basics of Sensu and how it works. I won't make any assumptions that you know anything about Sensu, as it is an introductory course. I will, however, assume that you do know a bit about systems in general, and some monitoring theory. If you are interested in monitoring systems, and you have heard of Sensu, then it's likely you know a bit about your systems already and you care enough to monitor them.

Unless otherwise specified, I'm going to focus only on the Open Source version of Sensu, and not the Enterprise version. (but I will mention the differences if they come up)

### First Steps

Before we install anything or make any config files, we have to start at some core concepts and talk about Sensu's architecture. Most of the misconceptions I see people have on the Sensu mailing list are a result of assumptions that users make about Sensu that are incorrect, because they assume that Sensu is like Nagios or other types of monitoring systems. It isn't. Lets talk about why that is.

#### The Sensu client

Let's start at the Sensu Client. The Sensu Client is a daemon or agent that runs on every server that you want to monitor. It is written in Ruby, and can run on Linux, BSD, or Windows.

The Sensu Client the process that *actually* executes checks. Keep that in mind this is the only place where actual check scripts run. Now, the Sensu Client can also *schedule* its own checks. These are called "standalone checks", because the client isn't dependent on getting instructions from the Sensu Server on what and when to run.

Now, the Sensu Client can't be that standalone, it has to do something with the results of the checks. For that, the Sensu Client puts its results onto the transport, which is RabbitMQ.

#### RabbitMQ

Here is where you might be thinking, Kyle, I'm hear to learn about Sensu, what does RabbitMQ have to do with it? Sensu uses a Queue to separate the actions between the clients and the server. Its a good thing, and the fact that Sensu doesn't reinvent the wheel here. It is true that this external component makes the overall architecture more complex, but it buys flexibilty that hopefully you will see exposed later.

But, back to RabbitMQ: the Sensu Client places result data onto RabbitMQ. Good.

#### Sensu Server

The Sensu Server is the daemon that pulls result data off of the queue and acts on that data. That action is usually in the form of executing _handlers_. Handlers are programs that read in the event data from stdin, and do something like email you or talk to pagerduty.

The Sensu server can *also* ask for checks to be executed on the Sensu clients. These are called subscription-based checks, because the clients have to "subscribe" to a particular tag, like "webserver". The Sensu server puts a request for a particular check, say `check_http` to be executed by all clients that are subscribed to the "webserver" tag. Remember this is contrast to "standalone" checks where the Sensu-client does the scheduling.

The differences between subscription-based checks and standalone checks is also a common source of confusion amongst new Sensu users. I'll cover this in-depth in a different course.

#### Redis

Sensu has to keep state somewhere. The state includes things like check history, timestamps, whats up, whats down, etc. Sensu is designed to store that state in Redis. Redis, if you haven't heard of it, is a key-value store. The disadvantage to you as a user is that you must run a Redis instance. The advantage is that the Sensu-server itself is stateless, and easier to scale, and it doesn't have to re-invent the wheel for storing state, which makes the Sensu codebase smaller.

#### Sensu API

While Sensu-server does it's one thing (operate on events and execute handlers), and Redis does its state-storing thing, there is also the Sensu-API process. Its job is to just talk to Redis and RabbitMQ and provide a rest interface to what is going on. Handlers themselves often use this API, as well as dashboards and external tools.

#### Dashboard (Uchiwa)

With any monitoring system, it is nice to have a dashboard. Would you believe that Sensu doesn't have a built in dashboard? It might be surprising if you are coming from a monolithic monitoring system where all this stuff is contained in a single process. But in Sensu it is separate. The canonical Sensu dashboard is Uchiwa. Uchiwa is written in Go, and provides a nice "plane of glass" to expose what is going on with your systems. It only needs to connect to the Sensu API. We'll be investigating this component in a later lecture.


### Conclusion

As you can see there are lots of parts here. Sensu is built with small components that do dedicated things. It uses proven external solutions for some of the heavy lifting (like RabbitMQ and Redis). The end result requires you as an engineer to understand your system better, it is *not* a black box. But it does mean that things scale better, and there is a lot of flexibilty that come out of this setup that wouldn't be possible with a more monolithic system. 
