## Using Puppet With Sensu - Part 3

### Integrating Puppet Sensu Checks with the Rest of Your Puppet Code

```pupppet
class profile_webserver (
  $port = 80,
){

  class { 'apache':
    listen_port => $port,
  }

}
```

Wouldn't it be great if you could get the monitoring to go right with it?

```puppet
class { 'apache':
  listen_port => $port,
} ->
sensu::check { 'check_apache':
  command => "/opt/sensu/embedded/bin/check-http.rb --port ${port} --host localhost",
}
```

Now you can apply this apache class to whatever machine you want, and the
monitoring will go with it. There is really good cohesion between your
configuration of your software and the monitoring of that software.

Because these are standalone checks, they apply no matter what subscriptions
the Sensu client is subscribed to. That means if you applied this class
to your production webserver, or if it was applied to some app server, both
would get the same monitoring. I think this is just great!

To re-iterate though, I don't think that the monitoring itself belongs
*in* the apache module. No, the Apache module can just do its thing:
install apache. It is the "profile" that combines the two together.
In this particular instance I called it `profile_webserver`, because
that is the particular function it does.

## Conclusion

Sensu was designed to be used with configuration management, and with
puppet it really shows. The Sensu puppet module is a *first-class*
citizen in the puppet world, it can do pretty much anything.

And in the end you *want* it to do everything. More specifically,
you want to make the most out of this automation so that you
deploy reproducible infrastructure, that you never have to
"remember" to add it to Nagios or whatever. With Puppet and Sensu,
there is a really good bond between the software and the monitoring.
