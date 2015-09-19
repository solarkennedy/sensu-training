# Using Ansible to Install and Configure Sensu - Part 2

## Installing the Mailer Handler

Now that we have the basic Sensu Components installed, we are ready to start
adding more real-life configuration. We'll start with an email handler, just
like in the introductory course, so you can get emails when things go wrong.

Remember that in the Introductory Course we used the embedded Sensu ruby
to install these handlers. I think this is a pretty sane way to do this,
as it means that you don't have to depend on the system-installed ruby,
which may not be up to date.

We can use ansible to install gems for us, no problem:

    http://docs.ansible.com/ansible/gem_module.html

But if we included this gem without any extra options, it would install
it using the system-ruby, if available. For us, we want to override the
`executable` parameter, to point to Sensu's gem.

But where are we going to put this task?

There are many ways to organize ansible playbooks. You could even
just modify the Sensu playbook to include the gems you need, but
I would like to leave the third-party playbooks alone and just
tack on my business requirements on top.

To do this, I'm just going to make a `sensu_server_extras` playbook
and put it in the roles folder, and put all my extra stuff in there.

    mkdir -p roles/sensu_server_extras/{files,tasks,handlers,defaults}
    vim roles/sensu_server_extras/tasks/main.yml

And the handlers tasks will take care of installing handlers. Here is
were we can install that the actual rubygem:

    ---
    - gem: name=sensu-plugins-mailer executable=/opt/sensu/embedded/bin/gem user_install=no state=present

Note the important options here. Obviously we need the name, and we do need to set the path
to the gem executable. Additionally we need to turn off `user_install`, as that
defaults to yes in ansible.

And now we can include the `sensu_server_extras` playbook to the list
of roles to include:

    vim site.yml
    - sensu_server_extras

And now lets get that gem installed

    ansible-playbook site.yml

We got an error installing that gem. This is a very common error when installing
gems with native extensions. The solution is to install g++, and more generally
by installing the `build-essential` package on Ubuntu.

    - apt: name=build-essential state=installed
    ansible-playbook site.yml

Now let's verify the actual script is in place:

    ls /opt/sensu/embedded/bin/

### Configuring the Mail Handler

Now how are we going to configure this handler?

Looking at the docs for the Sensu playbook, there are variables
we can set to define arbitary configuration:

    https://github.com/Mayeu/ansible-playbook-sensu#configuration-organisation

There are variables for the `sensu_settings`, which is a big catchall,
and the `sensu_handlers` hash:

    https://github.com/Mayeu/ansible-playbook-sensu#general-variables

But I think it would be nice if this same playbook deployed the handler
and configured the handler in the same playbook. I don't, personally, like
the big single variable for all the arbitrary `sensu_settings`, when
Sensu handles multiple configuration files so easily.

To that end, for this lecture I'm going to install the mailer handler
and configure it in the `sensu_server_extras` playbook like this:

    vim roles/sensu_server_extras/defaults/main.yml

    ---
    sensu_mail_configuration:
      handlers:
        mailer:
          type: pipe
          command: /opt/sensu/embedded/bin/handler-mailer.rb
      mailer:
        admin_gui: http://admin.example.com:8080/
        mail_from: sensu@example.com
        mail_to: monitor@example.com
        smtp_address: smtp.example.org
        smtp_port: 25
        smtp_domain: example.org

In the `sensu_server_extras` playbook I'm setting up a variable to store
the sensu mailer handler configuration, *and* the configuration snippet
for the mailer plugin. I've set this to be in the `sensu_mail_configuration`
variable.

    vim roles/sensu_server_extras/tasks/main.yml

    - name: sensu mailer config
      copy:
        content='{{ sensu_mail_configuration | to_nice_json }}'
        dest=/etc/sensu/conf.d/mailer.json owner=sensu group=sensu mode=0640
      notify:
        - restart sensu server

Now in my tasks I have a task to just output that variable directly into the
filesystem in json form. 

I am referencing a handler from the other playbook, so I'm going to cross-include
it:

    vim roles/sensu_server_extras/handlers/main.yml

    ---
    - include: ../../Mayeu.sensu/handlers/main.yml

I'm not 100% sure this is the *best* way to do this, but it is certainly *a*
way to do it, and I like that it doesn't have to interact with the `sensu_setting`
variable or other variables from a different module. In this sense it is sort of
self-contained.

    ansible-playbook site.yml

Now let's double check the output file

    cat /etc/sensu/conf.d/mailer.json
    tail /var/log/sensu/sensu-server.log

The file on disk looks ok, and the sensu server seemed to accept it.
The Sensu config loading code does a big glob over all the files in here,
and it doesn't matter that the mail config is in it's own file.

## Adding A Client

So far we've got the *server* aspects of sensu setup, but we haven't talked
much about the sensu client. The Sensu Ansible playbook we have been using
actually enables the client by default. But what would it look like if you
were configuring a standalone client?

    vim site.yml

    - hosts: localhost
      roles:
        - Mayeu.sensu
      vars_files:
        - sensu-server-vars.yml

If we were configuring just a standalone client, we would want to still
include the Sensu role, and we would even want to include the same
sensu-server-vars file to prevent duplication.

But we would want to *not* install the sensu server:

    vars:
      - sensu_install_server: no

This will work, but I want to do something similar to what we did before, were
we installed a disk check. We have to have *some* playbook to put that in,
so I'm going to make a `sensu_client_extras` playbook.

    cp -a roles/sensu_server_extras roles/sensu_client_extras

And instead of instaling the handler, we'll install the disk check:

    vim roles/sensu_client_extras/tasks/main.yml

    ---
    - gem: name=sensu-plugins-disk-checks state=present executable=/opt/sensu/embedded/bin/gem user_install=no
    
    - name: sensu disk check
      copy:
        content='{{ sensu_disk_check | to_nice_json }}'
        dest=/etc/sensu/conf.d/check_disk.json owner=sensu group=sensu mode=0640
      notify:
        - restart sensu client

That should install the gem and deploy a file with the disk check in it.

    vim roles/sensu_client_extras/defaults/main.yml

    ---
    sensu_disk_check:
      checks:
        check_disk:
          command: /opt/sensu/embedded/bin/check-disk-usage.rb
          standalone: true
          interval: 60
          handlers: ['mailer']

Now if we apply this, we should get a new gem installed for our disk check, and a
new disk check configuration, and the sensu client should be automatically
restarted to pick up on it.

    ansible-playbook site.yml

And if we tail the client log, we should see that this check is being processed:

    tail /var/log/sensu/sensu-client.log  -f

## Conclusion

We have only setup a very basic Sensu installation with Ansible.

There are many ways to organize ansible code. I think what is presented here
is certainly *a* way to do it. I would imagine that if you had existing roles
for thing like "webserver", that playbook would include say, and apache playbook
as well as have tasks for monitoring apache, similar to the disk check
that was setup in this lecture.

Let's make an example and see what that might look like:

    ansible-galaxy install geerlingguy.apache
    mkdir -p roles/webserver/{files,tasks,handlers,defaults,meta}
    vim roles/webserver/meta/main.yml

    ---
    dependencies:
    - { role: geerlingguy.apache }

   vim site.yml
   - webserver

We've made a kind of webserver wrapper role that depends on an apache
playbook. So far that is all that it does. Lets apply this:

   ansible-playbook site.yml

Now, lets see what it would like like if we added sensu monitoring to this
role:

    vim roles/webserver/defaults/main.yml

    ---
    sensu_check_http:
      checks:
        check_http:
          command: /opt/sensu/embedded/bin/check-http.rb --url 'http://localhost/'
          standalone: true
          interval: 60
          handlers: ['mailer']

We define a sensu check for check http, now lets make the task that actually
deploys that check:

    vim roles/webserver/tasks/main.yml

```
---
- gem: name=sensu-plugins-http state=present executable=/opt/sensu/embedded/bin/gem user_install=no
- name: sensu check http
  copy:
    content='{{ sensu_check_http | to_nice_json }}'
    dest=/etc/sensu/conf.d/check_http.json owner=sensu group=sensu mode=0640
  notify:
    - restart sensu client
```

And the last thing we need is the cross reference to the sensu client ansible handler:

    vim roles/webserver/handlers/main.yml

```
---
- include: ../../Mayeu.sensu/handlers/main.yml
```

And that adds the monitoring to the webserver role. Let's make Ansible deploy this:

    ansible-playbook site.yml

    cat /etc/sensu/conf.d/check_http.json
    tail -f /var/log/sensu/sensu-client.log

I like the idea of having a playbook contain the checks that it needs, and
all the associated configuration. That would mean that any host that included
the `webserver` role would automatically include the monitoring with it,
and nobody would have to remember to edit the top level `sensu_checks` variable.

Obviously your mileage may vary. The point of this lecture is not to
prescribe a certain way of doing this, but to inspire you to make your
own playbooks and roles that integrate Sensu checks in the way that makes
most sense for you. Hopefully that happened and you can see now how you
might do that.

Be sure to check out the show notes for the exact commands I used in this
lecture, as well as the code samples for the example playbooks, including
the webserver one that combines Apache and Sensu.
