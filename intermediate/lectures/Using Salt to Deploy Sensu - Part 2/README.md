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

Specifically it looks like this formual is configured to recursivly copy
anything in the conf.d folder over to the filesystem if we are applying
the Server State stuff.

And inside the formula in that conf.d folder is a hard-coded `check_cron.json` file:

    https://github.com/saltstack-formulas/sensu-formula/tree/cf9f0ef98faffa5d4601b54912b482da352203b9/sensu/files/conf.d

I'm embarrased to say that, at least at the time of this recording, I'm not
able to figure out how to not have this check, without forking this
formual and removing that file. For now I'm going to ignore it, but
this surprised me. I'm tempted to make a PR to remove it.

### Deploying a Mail Handler

In order to make Sensu useful, we need at least one handler. Let's install
the email handler, just like we did in the introductory course.

The Sensu Salt formual has a method to install arbitrary gems to make
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

The first error is the normal rabbitmq user thing. The real error here is
that Salt couldn't install this gem because it was missing `g++`. Generally
in Ubuntu this is solved by installing the `build-essential` package. But
where are we going to tell Salt to install this?

There are lots of ways to organize Salt code. For this lecture, I'm going
to store the extra server stuff into a state file called `sensu_server_extras`.
This will give us a place to put stuff, and potentailly have room to grow.

I don't really want to fork the official Sensu formual. I would like to leave
it alone and then just add my business requrerements on top, if possible.

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

We somehow need to get a config file in the conf.d directory for configuring
the mailer handler. We could make the file by hand and then have Salt
copy it over for us, but I would rather use Pillar and define the configuration
there.

What if we just used our `sensu_server_extras` state file to just conver Pillar
data into json form on-disk for sensu to use? What would that look like?

    vim sensu_server_extras.sls

```
/etc/sensu/conf.d/mailer.json:
  file.managed:
    - contents: '{{ pillar["sensu_server_extras"]["mailer_configuration"] | json() }}'
    - watch_in:
      - service: sensu-server
```

Now we have refrenced this pillar variable, let's go make it exist:

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
per the sensu docs, and I've added in the configuration for the mailer itself
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
customization, and I like the idea of self-containted state files.

Neither Salt nor the Sensu Salt Formula have a generic way to deploy
these files in a generic way, other than just doing the `json` trick
and defining the hash in Pillar.

First let's add the sensu rubygem for the disk check, so we have
the script installed.

    cd /srv/pillar
    vim sensu.sls

Now I could add this list of gems to be installed in the pillar variable, like 
we did with the mailer handler, but I don't really like that. The reason I don't
like that is that it requires me to maintain the "canonical" list of rubygems
that are installed for sensu. Wouldn't it be nice if the state file that installed
a disk check was responsible for installing the disk check *as well* as configuring
that disk check? That way it wouldn't have to "assume" that the operator remembered
to add the gem to this global list.

Well, Salt doesn't really have a way to install Sensu gems, but it does have a method
to install gems in general:

    https://docs.saltstack.com/en/develop/ref/states/all/salt.states.gem.html

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
60 second and to use the mail handler we defined earliar.

    salt-call  --local state.highstate

Ok, let's verify the check script exists

    ls /opt/sensu/embedded/bin/check-disk-usage.rb

Ok that is there, how about the config file for sensu to check the disk?

    ls -l ls /etc/sensu/conf.d/check_disk.json
    jq . /etc/sensu/conf.d/check_disk.json

Looks ok. Is Sensu reading that and acting on it?

    tail -f /var/log/sensu/sensu-client.log

## Conclusion
