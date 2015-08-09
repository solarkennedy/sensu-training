## Tinkering With Uchiwa

You may notice right off the bat that you don't see any events?

This might surprise you, and this is another very common misconception about Sensu that people have, especially coming from other monitoring systems. Sensu is not a "green light" dashboard.

Green-light dashboards don't scale very well. If you have 1000 sensu clients each with 1000 checks that are all green, that is 1 million events that sensu and the dashboard would have to process.

Sensu's event-driven architecture means that it only shows things that are red. This is a good thing, hopefully you can just get used to it.

### Clients

You can see the client here. Sensu *does* track the status of the clients.

You can Silence a client if you don't want it to make any noise from the handlers by clicking this volume icon. This *will* silence all the checks and the client itself. Which is what most people see as the expected behavior.

### Checks

Checks will show *only* server-side checks. The Sensu-API is not aware of standalone checks that are only defined on the clients. This can also be confusing to newcomers, because they expect to see every check ever here.

But, if you are running a Sensu-client on the same host as the Sensu Server, then you will see those checks here.

### Stashes

Stashes are Sensu's kinda free-form key-value store. Sensu handlers use the slience stashes to mark a host or check as silenced. But they can be anything! This makes Sensu very flexible, but taking advantage of this feature is a little outside the scope of this video.

The important thing to know is that Silences are implemented by making a stash here. And in this view you can see all the stashes.

### Aggregates

Aggregates are an advanced topic, they have to do with executing a check over the course of many hosts and doing a tally or aggregate of the results and acting on it.

### Datacenter

Here is where we see that multi-site capability show up. We only defined one site, and it shows up here. If you were building a multi-site setup, the health of the individual endpoints would show up here.
