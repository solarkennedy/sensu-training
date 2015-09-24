# Deploying Third-Party Checks and Handlers

I hope that you've watched at least *one* of the configuration
management lectures. I don't care if it was Puppet, Chef, Ansible
or Salt, they are all tools for reproducing infrastructure
reliably, and they can all install Sensu stuff.

In each of those configuration management lectures I showed how to
install checks and handlers using the Sensu omnibus. Let's talk
about this in more depth.

## Installing the mail-handler by hand

So what does it mean to install the mail-handler using the
Sensu embedded ruby?

Let's remind ourselves what the thing is:

    https://github.com/sensu-plugins/sensu-plugins-mailer

Yes it is on github, it is also a *realy* ruby gem:

    https://rubygems.org/gems/sensu-plugins-mailer

That means you can `gem install` it. If you have never used rubygems
before, gems are just the ruby-specific package manager for handling
ruby package installation and dependencies.

Being a *real* gem comes with some benefits. It means they have version
numbers you can pin, you can install them with a single command, you can
stick them in a Gemfile and lock your dependencies. It is certainly a
step up compared to fetching something off of github: it is a real package.

## Installing the Gem

We can fetch this third-party plugin with a single command:

    /opt/sensu/embedded/bin/gem install sensu-plugins-mailer

Now what just happened, there? The first thing to make really
clear here is that we are using the embedded ruby. I don't have to
set a special path or any extra environment variables. Just
using the full path to the gem binary ensures that the gem
is installed in the embedded ruby gempath.

Let's look at the files:

    /opt/sensu/embedded/bin/gem contents sensu-plugins-mailer

You can see these are all self-contained in the Sensu embedded
ruby path. This action didn't involve the system ruby at all.

## Binaries

Let's see where the scripts actually ended:

    /opt/sensu/embedded/bin/gem contents sensu-plugins-mailer | grep bin

And let's look at one of these

    vim /opt/sensu/embedded/bin/handler-mailer.rb

You can see that at the top that the path to the sensu embedded ruby
is hard-coded at the top. This is a byproduct of the act of installing
this gem using the embedded ruby. Again, we don't need any special
environment variables or anything, we can just run this script directly,
and so can Sensu!

## Alternatives

Using this embedded ruby for installing third party checks and handlers
is really handy I think, but you by all means do not need to use it.

If you already know your way around a ruby interpreter, and have an
existing preferred method for distributing rubygems, you could
absolutely use that instead. In the end Sensu just needs some script to run,
so whatever works best for you is fine.

If you like using a system installed ruby and managing gems that way; go for
it. If you like bundler and rvm, you can do that too.

### Even more Alternatives

If you don't even like Ruby at all, you do *not* have to use is it.

Sensu is compatible with any script that returns nagios-compliant return
codes. This means good old nagios scripts too.

So while there are many available Sensu plugins that are packaged
as gems available for use:

    http://sensu-plugins.io/plugins/

## Conclusion

You absolutely can install the gems in whatever way is most comfortable
to you. If you don't have an existing method to install gems, then using the
embedded ruby sure is convenient.

But if you already have third-party existing Nagios checks, by all means
use them! Sensu was designed to interoperate with those, you should should
absolutely try to take advantage of that existing engineering.

Just because you have installed "Sensu" doesn't mean you are locked in only
to the sensu-plugins catalog here. These are just here for convenience,
Sensu can run any command.

In later lectures I'll even show you how to write your own Sensu checks and
handlers, for times when there isn't an existing plugin available for use.
