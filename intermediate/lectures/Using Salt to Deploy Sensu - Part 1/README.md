# Using Salt to Deploy Sensu - Part 1

## Getting Started

Welcome to "Using Salt to Deploy Sensu". The purpose of this lecture is to
demonstrate how to use Salt to install and configure Sensu. Specifically
my goal here is to reproduce the environment we setup in the introductory
course: where we had a Sensu server, client, api, dashboard, a disk check,
and a email handler.

### Installing Salt

To install Salt, I'm going to use the PPA, as I'm using an Ubuntu-based
VM:

    sudo add-apt-repository ppa:saltstack/salt
    apt-get update
    apt-get install -y salt-common

And at the time of this writing, I had to install python-msgpack

    apt-get install -y python-msgpack

As far as I can tell this has been fixed in unstable.

### Setting Up Salt for Masterless Mode

For the lecture, I don't really need a full Master and Minion setup, I'm just
going to be applying state to localhost, so I'm going to setup Salt to operate
in "masterless" mode by instructing it to look at just my local files:

    mkdir /etc/salt
    vim /etc/salt/minion
    #
    file_client: local
    file_roots:
      base:
        - /srv/salt
    mkdir /srv/salt

And now I'll prepare a `top.sls` file, even if there is nothing in it yet:

    base:
      '*':
        - TODO

## Installing the Sensu Salt-Formula

There are number of ways to install Sensu with Salt.
On the official Sensu project, there is a tree available:

    https://github.com/sensu/sensu-salt

But it looks a little old with not much activity.

However, there *is* an official Salt Formula for Sensu:

    https://github.com/saltstack-formulas/sensu-formula

Which does look active, and at the time of this recording, looks like
the best way to install Sensu using Salt, so that is what I'll use.

To use this Salt Formula, I'm going to store it in the location
recommended by the docs, which is `/srv/formulas/`. I'm going to
download this formula manually for now instead of using git:

    mkdir -p /srv/formulas
    cd /srv/formulas
    wget https://github.com/saltstack-formulas/sensu-formula/archive/master.tar.gz
    tar xf master.tar.gz
    rm master.tar.gz
    mv sensu-formula-master sensu-formula

It is kind nice to have third party formulas installed like this for use.
Now I'm going to add this path to my `file_roots` parameter, so that Salt
knows where to find them

    vim /etc/salt/minion

```
file_roots:
  base:
    - /srv/salt
    - /srv/formulas/sensu-formula
```

Now would be a good time to look at 
[the sensu-forumula docs](https://github.com/saltstack-formulas/sensu-formula#sensu-formula)

I kinda want all of these to get started, let's add them to the top.sls:

    vim /srv/salt/top.sls

```
base:
  '*':
    - sensu
    - sensu.client 
    - sensu.server
    - sensu.api
    - sensu.uchiwa
```

Now, the docs do say that it is our responsibility to install RabbitMQ and Redis.
I actually like that this formula doesn't install those for us.

But for now, let's see what happens when we try to apply these states:

    salt-call  --local state.highstate

Let's look at the errors we got, which we totally knew we were going to get:

Looks like Uchiwa needs some more config. Sensu-server and Sensu-api are dead,
presumeably because we don't have RabbitMQ or Redis ready.

## RabbitMQ with Salt

Let's do RabbitMQ next. For Installing RabbitMQ with Salt, I'm going to use
the official rabbitmq-formula:

    https://github.com/saltstack-formulas/rabbitmq-formula

I'll download that formula manually:

    cd /srv/formulas
    wget https://github.com/saltstack-formulas/rabbitmq-formula/archive/master.tar.gz
    tar xf master.tar.gz
    rm master.tar.gz
    mv rabbitmq-formula-master rabbitmq-formula

And now I'll add this formula path to our list of `file_roots`:

    vim /etc/salt/minion

```
file_roots:
  base:
    - /srv/salt
    - /srv/formulas/sensu-formula
    - /srv/formulas/rabbitmq-formula
```

Now what states do we want? Well we know we want the normal rabbitmq server,
we'll certainly need some config, even if I haven't setup anything for Pillar
yet. The Sensu docs do recommend installing the latest version of Erlang and
RabbitMQ, so I'll go for rabbitmq.latest:

    cd /srv/salt
    vim top.sls

```
    - rabbitmq.latest
    - rabbitmq.config
```

But this won't be enough, because somewhere we will have to define rabbitmq
users and vhosts. To do that, we are going to need "The Pillar".

## Setting Up Pillar

Following best practices, I'm going to setup a simple Pillar structure
so I have a place to separate my configuration from my code.

    vim /etc/salt/minion

```
pillar_roots:
  base:
    - /srv/pillar
```

    mkdir /srv/pillar
    vim /srv/pillar/top.sls

```
base:
  '*':
    - rabbitmq
```

Now that we have pillar looking at the rabbitmq file, let's look at the example file
provided by the RabbitMQ Salt formula:


    cd /srv/pillar
    cp /srv/formulas/rabbitmq-formula/pillar.example /srv/pillar/rabbitmq.sls
    vim rabbitmq.sls

Now let's prune this down to just what we know we need for Sensu and go from there:

```
rabbitmq:
  vhost:
    '/sensu':
      - owner: sensu
      - conf: .*
      - write: .*
      - read: .*
  user:
    sensu:
      - password: password
      - perms:
        - '/sensu':
          - '.*'
          - '.*'
          - '.*'
``` 

    salt-call  --local state.highstate

Now with that in place, let's see what the logs say now:

    tail /var/log/sensu/sensu-server.log

Still invalid credentials. Sure we setup rabbitmq, but we haven't
setup Pillar for Sensu for course! Let's setup Pillar for Sensu and fill in
the configuration blanks

    cd /srv/pillar
    cp /srv/formulas/sensu-formula/pillar.example /srv/pillar/sensu.sls
    vim top.sls
    - sensu
    vim sensu.sls

```
sensu:
  server:
    install_gems: []
  client:
    embedded_ruby: False
  rabbitmq:
    host: localhost
    user: sensu
    password: password
  api:
    user: admin
    password: password
  ssl:
    enable: False
  uchiwa:
    sites:
      site1:
        host: localhost
        user: admin
        password: password
```

## Installing Redis

Next we need redis installed. I'm going to use the official redis-formula
for Salt:

    https://github.com/saltstack-formulas/redis-formula

I'll download it manually like the other formulas:

    cd /srv/formulas
    wget https://github.com/saltstack-formulas/redis-formula/archive/master.tar.gz
    tar xf master.tar.gz
    rm master.tar.gz
    mv redis-formula-master redis-formula

    vim /etc/salt/minion

And now we will add the redis state to be top file:

    vim /srv/salt/top.sls

I think redis is simple enough that we won't need any extra pillar config.

    salt-call  --local state.highstate

And now let's look at the sensu server logs...

And it looks like everything is working!

And is Uchiwa up?

Next we'll add all the extra stuff like checks and handlers.
