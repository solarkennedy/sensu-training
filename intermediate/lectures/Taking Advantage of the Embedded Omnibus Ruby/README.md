# Taking Advantage of the Embedded Omnibus Ruby

## Intro

You may remember me mentioning before in the introductory course that Sensu is
distributed as an "omnibus package". That means it comes its own isolated ruby
interpreter and gems, completely isolated from the system-installed Ruby, if
any.

This is a good thing for Sensu, it means you have predictable deployments,
regardless of the distro you are on.

In previous lectures I've demonstrated how to use this Ruby to install handlers
and checks. But say you really want to use this Ruby for everything, so
much that whenever Sensu runs anything Ruby related it will use the embedded
Ruby.

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

But how the heck does `EMBEDDED_RUBY=true` actually work? Let's find out where
that actually activates.

    https://github.com/sensu/sensu-build/blob/f872cc5f3d0345b636e73505b49e8230c836b0a8/sensu_configs/default/sensu

This is where `EMBEDDED_RUBY` is actually set. You can see right now it
defaults to false. This is definitely an opt-in kinda thing, it would be a
little surprising if the Sensu-ruby took over by default.

But if you know you want to use Sensu's Ruby as the default ruby, and you set
this to `true`. What does that actually do?

    https://github.com/sensu/sensu-build/blob/f872cc5f3d0345b636e73505b49e8230c836b0a8/sensu_configs/init.d/sensu-service#L166

This is an example of one of the init scripts. You can see that if this is
true, the init script will set the embedded Ruby's bin folder to be first in
the path.  Also it will set the `GEM_PATH` to use the Sensu-embedded-ruby's
Gems first, instead of what might be on the system.

That's it, no magic, just bash. Nothing specific to the Sensu user or anything,
it just sets the `PATH` and `GEM_PATH`.

On the one hand this can be convenient, but it does mean that if you need to
reproduce *exactly* how Sensu is executing checks or handlers, you need to
remember to do the same thing. It isn't very explicit, which is I prefer the
second method...

### Method 2: Hard-coding Shebangs (#!)

The other way to use this ruby is to make the she-bang directly invoke it. This
is a little easier to do if you control the script, and it is not a host-wide
setting, which is kinda nice.

This is the method I've used in all the other lectures so far, mostly because
it is so reproducible. It doesn't matter what your environment variables are,
you can run the command with the full path and it will always use the right
ruby.

#### Looking at the ruby

Lets see what we have to work with:

    /opt/sensu/embedded/bin/ruby --version

So Ruby 2.0.0, which is decently new. Lets see what gems are available:

    /opt/sensu/embedded/bin/gem list | less

These are the actual gems that Sensu uses, so be careful when adjusting these.

#### Using the Ruby

Of course if you want to use the embedded ruby on a script you can simply put
that ruby into the she-bang of the script.

    #!/opt/sensu/embedded/bin/ruby

And of course you can simply invoke a ruby script with that interpreter directly:

    #!/opt/sensu/embedded/bin/ruby my-script.rb

It may be more verbose, but it is explicit about exactly which ruby to use.

## Conclusion

That is all I really wanted to say about the embedded ruby. In the other
lectures you've seen me use it to install and run handlers and checks, but I
just wanted to touch now what it means to set `EMBEDDED_RUBY=true`. You don't
need to set it to be true to take advantage of the omnibus ruby, you can simply
call scripts by their full path instead. You should only really set
`EMBEDDED_RUBY=true` if understand what it means to set it. And of course all
it does is change the paths in the init script, no magic. But now you know!
