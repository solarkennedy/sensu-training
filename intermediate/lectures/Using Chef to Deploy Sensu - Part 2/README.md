## Using Chef to Install and Configure Sensu

### Installing a Disk Check

Just like in the introductory course, I would like to install a disk check from
from Sensu plugins github project. We are going to do the same thing as before
were we install it using the Sensu omnibus ruby.

With Chef we can use the `sensu_gem` provider to get it installed. Remember
that only the Sensu client executes checks, so this code should be associated
with the chef recipe that does client stuff.

    vim cookbooks/sensu_server/recipes/default.rb
    sensu_gem 'sensu-plugins-disk-checks'

With the check gem installed, we can configure the check:

    sensu_check 'check-disk' do
      command "/opt/sensu/embedded/bin/check-disk-usage.rb"
      standalone true
    end

    chef-solo -o sensu_server --config solo.rb

Lets inspect the actual configuration file that Chef made for that:

    cat /etc/sensu/conf.d/checks/check-disk.json

In your infrastructure you will have to make the call between defining standalone
checks on the clients like this, or doing subscription checks and configuring
clients to subscribe to certain tags. I like standalone checks myself, as it makes
it more straightforward to add Sensu checks *with* particular wrapper recipes.

You could imagine a cookbooks that wraps apache stuff together. That cookbook might
have a monitoring recipe included with it. This would keep the recipe kinda
"self-contained", and any role that included that cookbook would get the
monitoring with it, regardless of the tags it was subscribed to.


## Installing a Email Handler

Just like in the introductory course, lets get this sensu-server up and running
with an email handler so you can get email alerts.

Handlers are defined and executed on the server, so this code will go along with
the other server stuff.

We'll need the gem and the sensu-handler config:

    vim cookbooks/sensu_server/recipes/default.rb
    sensu_gem 'sensu-plugins-mailer'

    sensu_handler "mailer" do
      type "pipe"
      command "/opt/sensu/embedded/bin/handler-mailer.rb"
    end

Now we need the configuration *for* the mailer plugin. For that we use the
`sensu_snippet` construct to add in some arbitrary config:

    sensu_snippet 'mailer' do
      'admin_gui'    => 'http://localhost:3000/',
      'mail_from'    => 'sensu@localhost',
      'smtp_address' => 'localhost',
      'smtp_port'    => '25',
      'smtp_domain'  => 'localhost'
    end


And now a new error:

```
STDERR: ERROR:  Error installing sensu-plugins-mailer:
	ERROR: Failed to build gem native extension.

    /opt/sensu/embedded/bin/ruby extconf.rb
```

If you see this error, it might me one of two things. Maybe you are missing
the build-essential package, which contains make, a compiler, and other things
required to build native gem extensions. Or maybe you are like me and you were
running a virtualbox image with the default 512MB of ram, which is not enough
to run chef and gcc at the same time.

## Conclusion

I've kinda just scratched the surface of what you can use with Chef.
Like any configuration-management tool, the big idea is to get your
Sensu configuration down to something programmatic and reproducible.

Here we have reproduced the setup we had from the introduction course,
with only a few lines of code that we had to write. Obviously we are
standing on tall shoulders of those who wrote all the supporting cookbooks.

But, it will be up to you to make wrapping cookbooks that combine stock
cookbooks with sensu monitoring and supporting checks and plugins.

Check out the external resources of this lecture for more information on this
as well as all the commands and cookbooks used in this example.
