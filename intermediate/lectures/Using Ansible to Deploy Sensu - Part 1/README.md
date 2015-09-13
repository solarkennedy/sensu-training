# Using Ansible to Install Sensu - Part 1

## Getting Everything Ready

Welcome to "Using Ansible to Install Sensu". Just like all every configuration
management lecture, our goal here is to build an example Sensu environment
in a reproducible way. My specific goal here is to reproduce the exact setup
we made together in the Introductory course. We'll be installing all the
server and client components, a dashboard, and example check and email
handler.

First I'm going to install Ansible to get going

    sudo su -
    apt-get -y install ansible

For the lecture I'm going to use Ansible in local-mode. In production
you will probably have Ansible using SSH to do remote execution.

I'm going to edit my hosts file to reflect that

    cd /etc/ansible
    vim hosts
    localhost              ansible_connection=local
    ansible all -m ping

Good, ansible is installed and I can use it on localhost.

## Getting The Roles/Playbooks Ready

There is no official Ansible playbook for Sensu, but currently the
most feature complete playbook seems to be from `Mayeu`:

    https://github.com/Mayeu/ansible-playbook-sensu

I'll use the ansible-galaxy tool to download this playbook for use:

    ansible-galaxy install Mayeu.sensu

Now we need a `site.yml` file to serve as the entrypoint to associate
my localhost with the right roles:

    vim site.yml

    ---
    - name: Install Sensu Server Stuff
      hosts: localhost
      roles:
        - Mayeu.sensu

We are going to need more things for sure, but let's start with just this
and see what happens:

    ansible-playbook site.yml

Ok, our first error: this playbook expects ssl certs are available for use.
Let's go back and read the [manual](https://github.com/Mayeu/ansible-playbook-sensu#expectation).

The docs say that the playbook expects SSL certs to be available and that
RabbitMQ is listening on the SSL port. I have a whole dedicated lecture
dealing with RabbitMQ and ssl, so I won't talk about this subject too
much in this lecture. But for now I'm going to use the example set of
pre-generated certs and keys provided in the vagrant folder.

    mkdir files
    cp roles/Mayeu.sensu/vagrant/files/*.pem files/
    ansible-playbook site.yml

Our next error is talks about more missing files. These are mentioned in the
[manual](https://github.com/Mayeu/ansible-playbook-sensu#expectation) that we
didn't read fully...

It specifies that it expects a directory structure for sensu plugins, handlers,
and extensions. Let's make those folders, even if they are empty to start.

    mkdir -p files/sensu/{plugins,handlers,extensions}
    ansible-playbook site.yml

Alright, our next errors say that it can't start the sensu-api or sensu-server.
Now, we never setup RabbitMQ or redis, but let's see what the actual error is:

    tail /var/log/sensu/sensu-server.log

It looks like it the checks hash is defaulting to something invalid. I'm going to
take this opportunity to start a vars file to contain all the role variables
we are going to need to describe this `sensu_server` role. And in there I'll setup
a place to define some sensu checks, even if we just default to an empty hash for
now to satisfy the sensu-server.

    vim site.yml

    vars_files:
    - sensu-server-vars.yml

Now let's read up on what variables we can set for this playbook:
https://github.com/Mayeu/ansible-playbook-sensu#role-variables

Looks like `sensu_checks` is the variable we can set. Lets make it an empty
hash. I'm also going to do the same for `sensu_handlers` for now.

    vim sensu-server-vars.yml

    ---
    sensu_checks: {} 
    sensu_handlers: {} 

    ansible-playbook site.yml
    tail /var/log/sensu/sensu-server.log

Ok, now we get a transport connection failure. I think we are ready for installing
RabbitMQ and Redis. And we know we got it right when the Sensu-server and Sensu-api
startup.

## Installing RabbitMQ

Mayeu also has a very good RabbitMQ ansible playbook for use. For this lecture
I'm going to re-use that playbook. I do like how this Sensu playbook doesn't
presume to install RabbitMQ for you, but instead expects you to install
RabbitMQ with a different playbook. I certainly do not want to re-invent the
wheel here, so lets install the Mayeu RabbitMQ playbook:

    ansible-galaxy install Mayeu.RabbitMQ

And now we need to add the RabbitMQ playbook into our list of roles:

    vim site.yaml
    - Mayeu.RabbitMQ

    ansible-playbook site.yml

No red this time, but I'm skeptical that everything worked.

    tail /var/log/sensu/sensu-server.log

You might be able to guess what we are missing, based on what we did
in the introductory video. The smoking gun is in the RabitMQ logs:

    tail /var/log/rabbitmq/rabbit@vagrant-ubuntu-trusty-64.log

Ah ha, bad credentials. We never setup the credentials in the first place.
We need to configure Ansible to setup the Sensu RabbitMQ vhost and user.

Let's go back to the list of variables that the Sensu playbook exposes:

    https://github.com/Mayeu/ansible-playbook-sensu#role-variables


And now lets look at the RabbitMQ playbook and see how we might setup
RabbitMQ credentials:

    https://github.com/Mayeu/ansible-playbook-rabbitmq#vhost

For a vhost definition, it looks like the only thing we need is the name.
We could hard-code the string 'sensu', but we could also just re-use the
vhost variable from the Sensu playbook.

    vim sensu-server-vars.yml
    rabbitmq_vhost_definitions:
     - name:     "{{ sensu_server_rabbitmq_vhost }}"

For user definitions, we'll need the vhost, user, and password, all of which
are also variables that can come from the sensu playbook

    vim sensu-server-vars.yml

    rabbitmq_users_definitions:
      - vhost:    "{{ sensu_server_rabbitmq_vhost }}"
        user:     "{{ sensu_server_rabbitmq_user }}"
        password: "{{ sensu_server_rabbitmq_password }}"

If we got all that right, ansible should create the right RabbitMQ user for
sensu to use. Lets run our playbooks and watch:

    ansible-playbook site.yml
    tail /var/log/sensu/sensu-server.log

Looking at the timestamp on the log, it looks like the ansible playbook
for Sensu is not trying to get the Sensu server components back up.

At the time of this recording, there is an open Pull Request to make this
happen. Certainly seems like a bug, the desired state is to have the
Sensu stuff running of course.

    https://github.com/Mayeu/ansible-playbook-sensu/pull/21

Hopefully this is patched by the time you download this playbook, but for
now I'm going to quickly apply this patch to my local copy

    cd roles/Mayeu.sensu/
    wget https://patch-diff.githubusercontent.com/raw/Mayeu/ansible-playbook-sensu/pull/21.diff
    patch -p1 <21.diff
    cd ../../

Now that we've applied this patch, lets run the playbooks again:

    ansible-playbook site.yml

Now we get some red, and it is expected.

    tail /var/log/sensu/sensu-server.log

Of course, we haven't setup Redis yet. Let's try to find a redis playbook to install
and use.

Just looking at the Ansible Galaxy for Reids playbooks can be a bit overwhelming.

    https://galaxy.ansible.com/list#/roles?page=1&per_page=10&sort_order=average_score,name&f=redis

Narrowing down to just Ubuntu Trusty, which happens to be the platform I'm using
for this lecture, I get a few here:

    https://galaxy.ansible.com/list#/roles?page=1&per_page=10&sort_order=average_score,name&f=redis&platform=Ubuntu&release=trusty&reverse

I don't really need to install Redis from source here, and DebOps is a whole
set of opinionated things. This next one down looks pretty sane, just installs
redis from a package and makes sure it is running, which is good enough
for me.

    ansible-galaxy install geerlingguy.redis

    vim site.yml
    - geerlingguy.redis

    ansible-playbook site.yml 

All green, no Red. Is everthing running?

    ps -ef

Great, looks like we've got redis, rabbitmq, the sensu-server, api, and
Uchiwa. Let's check out uchiwa:

    http://localhost:3000/#/login

Hmm. What is the username and password?
That is configured via a variable in the Sensu playbook

    https://github.com/Mayeu/ansible-playbook-sensu#server-variables

Looks like the default username is 'uchiwa' with a password of 'placeholder'.

    http://localhost:3000/#/login

Obviously you could set these variables in our yaml to override them as
necessary, but I'll leave them for now.

And it looks like all the components are installed and running, which
sets up a good foundation for the next lecture, where we will install
additional pieces like checks, handlers, and client stuff.
