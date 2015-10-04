# Taking Advantage of the Embedded Omnibus Ruby

## Intro

You may remember me mentioning before in the introductory course that Sensu is
distributed as an "omnibus package". That means it comes its own isolated ruby
interpreter and gems, completely isolated from the system-installed ruby, if
any.

This is a good thing for Sensu, it means you have predicatable deployments,
regardless of the distro you are on.

### Advantages

The big advantage to this kind of deployment is that you *too* can take
advantage of this consistently deployed, modern ruby.

### Method 1: `EMBEDDED_RUBY=true`

There are two ways you can take advantage of this. The first way is by setting
`EMBEDDED_RUBY=true` in `/etc/default/sensu`:

   vim /etc/default/sensu

If you set this to true, then whatever service that runs on this host, either
the sensu-client or the sensu-server, will have the omnibus-ruby in the path
first. This means any ruby-based plugins will use *it* instead of whatever
system ruby is installed.

#### Mechanics of `EMBEDDED_RUBY=true`

### Method 2: Hard-coding Shebangs (#!)

The other way to use this ruby is to make the she-bang directly envoke it. This
is a little easier to do if you control the script, and it is not a host-wide
setting, which is kinda nice.

### Looking at the ruby

Lets see what we have to work with:

    /opt/sensu/embedded/bin/ruby --version

So Ruby 2.0.0, which is decently new. Lets see what gems are available:

    /opt/sensu/embedded/bin/gem list | less

These are the actual gems that Sensu uses, so be careful when adjusting these.

### Real Life Usage

So lets say you wanted to take advantage of this Ruby in a more real-life
scenario.

Lets say you were trying to deploy the community Pagerduty Handler.
