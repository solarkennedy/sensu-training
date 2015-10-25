# Installing and Using the Sensu-cli

## Intro

The sensu-cli is a nice command line tool that complements Sensu. It puts all
of the power of the Sensu-API on the command line, for easy interactive use and
for integrating Sensu with command line tools.

## Installation

The `sensu-cli` is not an official Sensu component. However, it is a normal
rubygem, and can be install however you like to install rubygems. Of course, I
like to install rubygems that are related to Sensu using the omnibus Ruby that
Sensu comes with:

    /opt/sensu/embedded/bin/gem install sensu-cli

Now the bin stubs for these Sensu-install ruby gems end up in the embedded
bin folder here:

    ls /opt/sensu/embedded/bin/

But I would like to have this just in my normal path, so I'm going to put this
in my path by adding a symlink

    ln -s /opt/sensu/embedded/bin/sensu-cli /usr/local/bin/
    which sensu-cli

## Background Prep

    sed -i "s/localhost/`hostname -f`/" /etc/sensu/conf.d/client.json
    /etc/init.d/sensu-client restart
    sensu-cli client delete localhost
    sensu-cli socket create -n check_http -o "CRITICAL: 400 bad" -s 2
    sensu-cli socket create -n check_mem -o "WARNING: Out of memory" -s 1
    sensu-cli socket raw '{"name": "check_ssh", "output": "CRIT: ssh is down", "status": 2, "source": "web02"}'
    sensu-cli socket raw '{"name": "check_disk", "output": "CRIT: Disk is full", "status": 2, "source": "sadserver"}'

## Usage

Now let's see what it can do. Out of the box the tool is very human-friendly,
outputting color where possible and has some nice ways to visualize the output.

For example, let's see a list of clients. The cli is organized very well:

    sensu-cli client list

So sure, you can see the list of clients. This is cool. Now with each subcommand
there are some output and filtering options:

    sensu-cli client list --help

The table format is a bit interesting:

    sensu-cli client list --format table

But I think JSON is the most interesting:

    sensu-cli client list --format json

I'll show you a bit more about what you can do with JSON output in a bit.
Let's take a look at some more of the features:

    sensu-cli --help

There is pretty much a 1 to 1 correspondence with what the sensu-cli can do and
what the Sensu-API can do.

* `aggregate` is the advanced feature I've hinted at before that allows you to
  execute a subscription check across a set of subscribers
* `check` allows you to see and issue check requests
* `client` is what I demonstrated right at first. You can see and delete
  clients.
* `event` allows you to list and resolve events, just like on the Sensu
  dashboard.
* `info` and `health` are commands to inspect the healthiness of the Sensu
  infrastructure.
* `silence` allows you to silence hosts or checks, which is handy to do from
  the command line
* `stash` allows you to add arbitrary stashes in Sensu's key-value store.
  `silence` is just a specific type of stash.
* `resolve` does the same thing as it does on the dashboard: it makes the
  failing event go away.
* `socket` is an interesting one. I have a later lecture demonstrating how you
  can push your own events to the local socket. The sensu-cli provides a
  convenient way to do this.

## Doing more interesting things

Lets say we wanted to take advantage of this command line tool and make it so
we put the list of currently failing checks in the message of the day of the
server, so when you log in you get some immediate situational awareness of what
is wrong with it.

Let's see if we can do it. We'll start with:

    sensu-cli event list

This is a good start, but we want to filter only the events for this local
host? Luckily we can do that:

    sensu-cli event list --filter name,`hostname -f `

This is good, but it is a little verbose for being in the message of the day.
The table format is a little better:

    sensu-cli event list --filter name,`hostname -f `  --format=table

But if we are going to do anything really fancy, we are going to have to
pull out exactly the fields we want. Specifically I'm kinda only interested
in "what" is failing and what the output is. This is where the JSON output can
come in hand:

    sensu-cli event list --filter name,`hostname -f `  --format=json

But what are we going to use to extract the fields we need? Well, you could
certainly write a program to do it, but I'm going to use one of my favorite
unixy tools: `jq`. You have seen me use `jq` a few times before in previous
lectures. Here I'm going to use it to print out just the check name and output:

    apt-get -y install jq
    sensu-cli event list --filter name,`hostname -f `  --format=json | jq -r '.[].check | .name + ":|" + .output'

And then one more filter I'll apply is to pipe it through the column tool to align it:

    sensu-cli event list --filter name,`hostname -f `  --format=json | jq -r '.[].check | .name + ":|" + .output' | column  -t  -s "|"

Any more complicated than this then I would want to put it into a script or
something.  But it is nice how much we can do just the command line with pipes
and unixy tools.

You could stick this in your `bash_profile` or motd and see right away what
alerts are failing for the host before you start investigating. Pretty cool.

## Having a Server Silence Itself

Let's say you would like to use the sensu-cli not just for reporting purposes,
but also to actually make your infrastructure interact with your monitoring
system.

Specifically, let's say that you want your servers to silence themselves for a
few minutes after they do a reboot. Or maybe you want your provisioning system
to silence newly provisioned servers for a bit. How could you use the sensu-cli
tool to do this? Well, it it can be as simple as a single command:

    sensu-cli silence -h

The first argument is the hostname itself

    sensu-cli silence `hostname -f`
    sensu-cli stash list

If you are going to silence the whole machine, then we won't provide a check
name. 

The owner might be the user, like root. Or if you know who owns the box from
other metadata, you could insert it here. For the reason argument you could say
"for a reboot" or "freshly provisioned". I like adding the expire argument so
that if something goes wrong, it will automatically be un-silenced eventually.
I don't think anything should be silenced indefinitely.

    sensu-cli silence `hostname -f` --owner root --reason "This server was just created" --expire 3600
    sensu-cli stash list

Likewise the server could "un-silence" itself, maybe after a chef run or
something like that.

## Silencing Clients

Let's do something else. Let's start by just getting a list of clients that
Sensu knows about.

    sensu-cli client list

This is a good start, but I really want just the raw hostnames. To do that
I'm going to use jq again:

    sensu-cli client list -f json | jq -r .[].name

Now that we have the raw names, we can pass them onto another tool. Let's say
it was an emergency and you needed to silence them all. You could use on of my
other favorite tools, `xargs`:

    sensu-cli client list -f json | jq -r .[].name | xargs --verbose -n1 --no-run-if-empty sensu-cli silence

So here we are taking every sensu client, and xargs will turn that and execute
the sensu-cli silence command. The n1 indicates that we want xargs to execute
one sensu-cli command per argument. I like the --verbose flag so it will print
out exactly what xargs is running. Let's see what happens...

Of course with this you could easily just use `grep` and filter only the clients
you are interested. 

## Emitting Alerts

Another interesting things you can do with the Sensu-cli is emitting your own events.

    sensu-cli socket create -h

This function allows you to create a Sensu event, without having to define the check
in the first place. This is an advanced feature. I have a dedicated lecture just
for explaining what this is and why you would want to use it.

## Resolving Alerts

The sensu-cli tool can also help with manually resolving alerts.

    sensu-cli resolve --help

Why would you want to do this? This can be handy if you are in a dynamic environment,
and checks and disappear as well as appear at will. The resolve command can
help "clean up" any residual checks. For example, let's say you were running a hosting
company and had a check for every customer that you had, and when a customer leaves,
you would want to resolve any lingering events that might have been open, so they don't clutter up the dashboard.

    sensu-cli socket create -n customer1 --output "Customer1 is DOWN" -s 2
    sensu-cli event list -f table

And then lets say customer1 left or was terminated, you could use the sensu-cli tool to resolve
that check manually:

    sensu-cli resolve `hostname -f` customer1
    sensu-cli event list -f table

Certainly your customer provisioning tool could interact with the Sensu api
directly, but not everything has to be that fancy, if you just have some script
to provision new customers, webservers, clusters, whatever, you can easily
integrate the sensu-cli with your command line tools.

## Conclusion

The sensu-cli is a powerful tool, with a 1 to 1 mapping against the Sensu API.
You can quickly integrate your existing scripts and tools with it. And if you
get really fancy, you can combine it with things like `jq` and do some pretty
crazy things. Check out the show notes for some even more complicated examples
of using this cli tool that I'm too embarrassed to admit that I've used them in
production.

## All Examples

### Have a host silence itself

```bash
sensu-cli silence `hostname -f` --owner root --reason "This server was just created" --expire 3600
```

### Silence any client that has the word "test" in the name

```
sensu-cli client list -f json |
  jq -r .[].name |
  grep "test" |
  xargs --verbose --no-run-if-empty -n1 sensu-cli silence
```

### Delete sliences older than 3 days

```bash
THRESHOLD=$(date +%s --date="3 days ago")
sensu-cli stash list --format json |
  jq -r "map(select( .[\"content\"][\"timestamp\"] < $THRESHOLD )) | .[].path " |
  xargs --verbose --no-run-if-empty -n1 sensu-cli stash delete
```

### Purge any checks that haven't checked in in a month

```bash
THRESHOLD=$(date +%s --date="1 month ago")
sensu-cli event list --format json |
  jq --raw-output "map(select( .[\"check\"][\"issued\"] < $THRESHOLD )) | .[] | .client.name + \" \" +  .check.name " |
  xargs --verbose --no-run-if-empty -n2 sensu-cli resolve
```
