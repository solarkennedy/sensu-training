# Using Salt to Deploy Sensu - Part 2

## What is this Cron Check?

Now that we have the basic Sensu infrastructure in place and managed by
Salt, let's do more and install the extras like handlers and checks.

The first thing we need to investigate is this `check_cron` that is already
showing up in Uchiwa:

    http://localhost:3000/#/client/site1/vagrant-ubuntu-trusty-64
    http://localhost:3000/#/client/site1/vagrant-ubuntu-trusty-64?check=cron_check

How did it get there? Let's look at the Sensu Salt formula more closely:

    https://github.com/saltstack-formulas/sensu-formula/blob/cf9f0ef98faffa5d4601b54912b482da352203b9/sensu/server.sls#L15

Specifically it looks like this formula is configured to recursively copy
anything in the conf.d folder over to the filesystem if we are applying
the Server State stuff.

And inside the formula in that conf.d folder is a hard-coded `check_cron.json` file:

    https://github.com/saltstack-formulas/sensu-formula/tree/cf9f0ef98faffa5d4601b54912b482da352203b9/sensu/files/conf.d

I'm embarrassed to say that, at least at the time of this recording, I'm not
able to figure out how to not have this check, without forking this
formula and removing that file. For now I'm going to ignore it, but
this surprised me. I'm tempted to make a PR to remove it.

### Deploying a Mail Handler

In order to make Sensu useful, we need at least one handler. Let's install
the email handler, just like we did in the introductory course.

The Sensu Salt formula has a method to install arbitrary gems to make
it easy to install handlers and dependencies:

    https://github.com/vexxhost/sensu-formula#sensuserver

It looks like all I need to do is add my gem to the `install_gems` list in
pillar.

    cd /srv/pillar
    vim sensu.sls
    - sensu-plugins-mailer

As a reminder, we are trying to install this gem:

    https://github.com/sensu-plugins/sensu-plugins-mailer

So we can get the `handler-mailer.rb` script, and then we'll configure it.

    salt-call  --local state.highstate

The first error is the normal RabbitMQ user thing. The real error here is
that Salt couldn't install this gem because it was missing `g++`. Generally
in Ubuntu this is solved by installing the `build-essential` package. But
where are we going to tell Salt to install this?

There are lots of ways to organize Salt code. For this lecture, I'm going
to store the extra server stuff into a state file called `sensu_server_extras`.
This will give us a place to put stuff, and potentially have room to grow.

I don't really want to fork the official Sensu formula. I would like to leave
it alone and then just add my business requirements on top, if possible.

So let's start this file, add it to our `top.sls`, and add in the
`build-essential` package so it gets installed.

    vim sensu_server_extras.sls

    build-essential:
      pkg.installed: []

    salt-call  --local state.highstate

Now that Salt says it installed it, let's confirm that Salt installed that gem
and the script is ready:

    ls /opt/sensu/embedded/bin/

Yep! Installed and ready to go. Now we need to configure this handler.

### Mailer Handler Configuration

We somehow need to get a config file in the `conf.d` directory for configuring
the mailer handler. We could make the file by hand and then have Salt
copy it over for us, but I would rather use Pillar and define the configuration
there.

What if we just used our `sensu_server_extras` state file to just convert Pillar
data into JSON form on-disk for Sensu to use? What would that look like?

    vim sensu_server_extras.sls

```
/etc/sensu/conf.d/mailer.json:
  file.managed:
    - contents: '{{ pillar["sensu_server_extras"]["mailer_configuration"] | json() }}'
    - watch_in:
      - service: sensu-server
```

Now we have referenced this pillar variable, let's go make it exist:

    cd /srv/pillar
    vim top.sls
    - sensu_server_extras.sls
    vim sensu_server_extras.sls

```
sensu_server_extras:
  mailer_configuration:
    handlers:
      mailer:
        type: pipe
        command: /opt/sensu/embedded/bin/handler-mailer.rb
    mailer:
      admin_gui: http://localhost:3000/
      mail_from: sensu@localhost
      mail_to: root@localhost
      smtp_address: localhost
      smtp_port: 25
      smtp_domain: localhost
```

Note here that I'm deploying the dictionary as-is. I've got a handler configuration
per the Sensu docs, and I've added in the configuration for the mailer itself
per the mailer docs. Obviously in your environment you will need to use settings
or variables that make sense for you.

Let's apply this state and see what Salt does...

    salt-call  --local state.highstate

Let's double check the file that Salt made:

    cat /etc/sensu/conf.d/mailer.json

I'm going to use the `jq` command to pretty print this:

    apt-get -y install jq
    jq . /etc/sensu/conf.d/mailer.json

Looks ok. You can see there is configuration here for Sensu, to define the
handler, as well as the configuration for the handler itself. Did the sensu-server
pick up and understand this file?

    tail -f /var/log/sensu/sensu-server.log

Looks like it did.

### Deploying our Own Check-disk

For the sake of reproducing what we built in the introductory lecture,
I would like to get a check-disk in place. To do that I know I want to install
the `sensu-plugins-disk-checks` ruby gem, and I know I need a configuration
file for Sensu to use to execute that check.

I'm going to follow a similar pattern as the `sensu_server_extras` state, because
I don't like the idea of forking forking the upstream formula just for
customization, and I like the idea of self-contained state files.

Neither Salt nor the Sensu Salt Formula have a generic way to deploy
these files in a generic way, other than just doing the `json` trick
and defining the hash in Pillar.

First let's add the Sensu rubygem for the disk check, so we have
the script installed.

    cd /srv/pillar
    vim sensu.sls

Now I could add this list of gems to be installed in the pillar variable, like
we did with the mailer handler, but I don't really like that. The reason I don't
like that is that it requires me to maintain the "canonical" list of rubygems
that are installed for Sensu. Wouldn't it be nice if the state file that installed
a disk check was responsible for installing the disk check *as well* as configuring
that disk check? That way it wouldn't have to "assume" that the operator remembered
to add the gem to this global list.

Well, Salt doesn't really have a way to install Sensu gems, but it does have a method
to install gems in general:

    https://docs.saltstack.com/en/latest/ref/states/all/salt.states.gem.html

But the Sensu Formula re-invents this wheel, twice even, once for the server
and once for the client:

    https://github.com/saltstack-formulas/sensu-formula/blob/master/sensu/client.sls#L84
    https://github.com/saltstack-formulas/sensu-formula/blob/master/sensu/server.sls#L57

I don't really like this. But for demonstration purposes, I'll leave the mail handler using
the formula method here, but for the disk check method I'll use the Salt gem installer:

    cd /srv/salt
    vim top.sls
    - sensu_client_extras.sls
    vim sensu_client_extras.sls

```
sensu-plugins-disk-checks:
  gem.installed:
    - gem_bin: /opt/sensu/embedded/bin/gem

/etc/sensu/conf.d/check_disk.json:
  file.managed:
    - contents: '{{ pillar["sensu_client_extras"]["check_disk_configuration"] | json() }}'
    - watch_in:
      - service: sensu-client
```

Note here that I'm telling Salt to use the Sensu embedded ruby gem binary to install
this gem.

Additionally I'm deploying the file for `check_disk.json`, and I'll get the actual
config from Pillar. And lastly we need to remember to restart the sensu-client when this
config file changes.

    cd /srv/pillar
    vim top.sls
    - sensu_client_extras
    vim sensu_client_extras.sls

```
sensu_client_extras:
  check_disk_configuration:
    checks:
      check_disk:
        command: /opt/sensu/embedded/bin/check-disk-usage.rb -i /vagrant
        standalone: true
        interval: 60
        handlers: ['mailer']
```
Note here that I'm defining this check to use the full path to the check-disk script.
We'll double check the path on that one. I'm configuring this to be a standalone
check, because I like standalone checks and this check should be self-contained,
and scheduled by the client. Additionally I've configured it to run every
60 second and to use the mail handler we defined earlier.

    salt-call  --local state.highstate

Ok, let's verify the check script exists

    ls /opt/sensu/embedded/bin/check-disk-usage.rb

Ok that is there, how about the config file for sensu to check the disk?

    ls -l /etc/sensu/conf.d/check_disk.json
    jq . /etc/sensu/conf.d/check_disk.json

Looks ok. Is Sensu reading that and acting on it?

    tail -f /var/log/sensu/sensu-client.log

It does look like the sensu client has picked up our config file and
has started to check the disk!

## Combining Sensu with an Apache Formula

Hopefully you can see the pattern here of making states that deploy Sensu
checks. Let's investigate a more real-world scenario: say you wanted
to use Salt to setup a webserver and have it monitored.

Well, first we'll need an apache formula to use. Let's download that in the
normal way:

    cd /srv/formulas
    wget https://github.com/saltstack-formulas/apache-formula/archive/master.tar.gz
    tar xf master.tar.gz
    rm master.tar.gz
    mv apache-formula-master apache-formula

    vim /etc/salt/minion
    - /srv/formulas/apache-formula

But I don't really want to include the "apache" formula in the top file. I
would like to think of the apache formula as a lower level abstraction,
and put together my own wrapper between Apache and Sensu. I'll just
call my state tree: webserver

    cd /srv/salt
    vim top.sls

Now this theoretical webserver isn't going to include all the sensu server
components, just the client stuff. And then I'll include my new webserver
state.

    - webserver

    cd /srv/salt 
    
    vim webserver/init.sls

To start, I'm just going to include the apache formula:

```
include:
  - apache
```

    salt-call  --local state.highstate
    ps -ef | grep apache

Ok, salt has installed apache, that is cool. Now let's monitor it?

We'll need a script to check apache, we could write one, or re-use an existing
nagios plugin, or we can install the sensu http check plugin:

    vim webserver/init.sls

```
sensu-plugins-http:
  gem.installed:
    - gem_bin: /opt/sensu/embedded/bin/gem

/etc/sensu/conf.d/check_http.json:
  file.managed:
    - contents: '{{ pillar["webserver"]["check_http_configuration"] | json() }}'
    - watch_in:
      - service: sensu-client
```

I'm going to do something very similar to the disk check, where I'm going
to install the check script I need, and deploy the config file that goes with
it in the same state.

Now I need to define the actual check configuration in pillar:

    cd /srv/pillar
    vim top.sls
    - webserver

Now I have a place to put my check configuration, in the webserver pillar
file:

    vim webserver.sls

```
webserver:
  check_http_configuration:
    checks:
      check_http:
        command: /opt/sensu/embedded/bin/check-http.rb --url "http://localhost/"
        standalone: true
        interval: 60
        handlers: ['mailer']
```

Here I'm defining the check hash for Sensu to use. My command is referencing the full
path to the check script, and I'm just using localhost as the url.

This is a standalone check because it will be executed on the client, I'm not working
with subscriptions in this case. And of course it will use the mailer handler we setup
previously.

    salt-call  --local state.highstate

Now let's watch the logs:

    tail -f /var/log/sensu/sensu-client.log

And it is checking http, 200 OK. Let's stop apache and watch it fail?

    /etc/init.d/apache2 stop
    tail -f /var/log/sensu/sensu-client.log

And now we get a connection refused. Great!

## Conclusion

There are many ways to organize Salt code. I really like the ability to re-use
existing formulas like RabbitMQ, Apache, Redis, and Sensu. I like the idea
that we can build a state tree that contains deploys a piece of software and
sets up the monitoring for it too, like this webserver state tree. I *don't*
like the idea of a single variable declaring all of the sensu checks for a
server.

Sensu tolerates having multiple config files that declare individual checks
very well, so having a state tree deploy it's own config file along side the
software works just fine.

The purpose of this lecture isn't to prescribe a particular way of organized
Salt code, as much as it is to inspire you to dream up your own ways of
integrating Sensu checks with Salt, with your existing states.

If you are curious about the example code I've used here, or need links to the
exact formulas I used in this lecture, check out the "external resource"
section for all those things.

And good luck, installing Sensu checks with Salt!
