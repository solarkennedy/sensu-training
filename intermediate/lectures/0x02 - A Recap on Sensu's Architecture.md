== Sensu Architecture Recap

=== Intro

If you have not taken the Sensu Introduction course, I encourage you to do so, because I cover the overall Sensu archtecture in depth there. But for the intermediate course I'm just going to do a quick refresher.

==== The Sensu client

The Sensu Client the process that *actually* executes checks. The Sensu Client can also *schedule* its own checks. These are called "standalone checks", because the client isn't dependent on getting instructions from the Sensu Server on what and when to run.

Now, the Sensu Client can't be that standalone, it has to do something with the results of the checks. For that, the Sensu Client puts its results onto the transport, which is RabbitMQ.

==== RabbitMQ

Sensu uses a Queue to separate the actions between the clients and the server. Sensu Client places result data onto RabbitMQ, the Sensu-Client also listens for requests to execute a check from the Server.

==== Sensu Server

The Sensu Server is the daemon that pulls result data off of the queue and acts on that data. That action is usually in the form of executing _handlers_. Handlers are programs that read in the event data from stdin, and do something like email you or talk to pagerduty.

The Sensu server can *also* ask for checks to be executed on the Sensu clients. These are called subscription-based checks, because the clients have to "subscribe" to a particular tag, like "webserver". The Sensu server puts a request for a particular check, say `check_http` to be executed by all clients that are subscribed to the "webserver" tag.

The differences between subscription-based checks and standalone checks is also a common source of confusion amongst new Sensu users. We'll talk more about the differences in a later lecture.

==== Redis

Sensu has to keep state somewhere. The state includes things like check history, timestamps, whats up, whats down, etc. Sensu is designed to store that state in Redis. 

==== Sensu API

The Sensu-API process's job is to just talk to Redis and RabbitMQ and
provide a rest interface to what is going on. Handlers themselves often use
this API, as well as dashboards and external tools.

==== Dashboard (Uchiwa)

Uchiwa is that nice "plane of glass" to expose
what is going on with your systems. It only needs to connect to the Sensu API.

=== Conclusion

As you can see there are lots of parts here. If you are going to run Sensu in production, you have to understand what talks to what, and what runs where. This is especially true when things don't work! You have to be able to troubleshoot your systems, know where the logs are, etc. Again the intro course covers each piece a little bit, and we'll cover other pieces in this intermediate course, and in the advanced course I cover even more stuff. 
