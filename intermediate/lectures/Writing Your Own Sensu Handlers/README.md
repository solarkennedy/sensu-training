# Writing Your Own Sensu Handlers

A "handler" is the name for the piece of code that Sensu executes
in response to recieving and event.

In the introductory course I mentioned that handlers simply take input
from stdin and then act on that input. And that is true!

Handlers can be as simple as just the `cat` command, that take the
input and spit it back out. For this lecture will make a more sophisticated
handler.

## What Language Handlers are Written In

Although you could write a Sensu handler in any language, most of them
are written in Ruby. Handlers are written in ruby to give them access
to a lot of helping ruby methods that come with the `sensu-plugin` gem.
These are helper for things like reading config out of `/etc/sensu`, or
handling the situation where checks are silenced.

Still though, when writing handlers in Ruby, you get a lot of boilerplate
for free. Similar to how when we wrote the check script in ruby, we got
a lot of similar command line parsing things that seems to be kinda
"magical", when we use the sensu-plugin class for handlers, we will
also get a lot of cool stuff.

## Getting Started

There isn't a ton of [existing documentation](https://github.com/sensu-plugins/sensu-plugin#handlers)
on how to write handlers, but there are lots of examples and prior art.

Let's start by copy/pasting the [show handler](https://github.com/sensu/sensu-community-plugins/blob/master/handlers/debug/show.rb)
, which is kinda the most minimal handler there can be:

```ruby
#!/opt/sensu/embedded/bin/ruby
require 'sensu-handler'

class Show < Sensu::Handler
  def handle
    puts 'Settings: ' + settings.to_hash.inspect
    puts 'Event: ' + @event.inspect
  end
end
```

Like before I'm going to make the call to hard-code the Sensu embedded ruby
in my shebang for the lecture. You will have to decide for yourself if this
is what you want in your own environment.

How are we going to actually test this handler? Certainly we could reproduce
a server environment and a purposely failing check. But I have a better idea.
Remember that handlers just take input from std-in and then operate on it?
Let's just give it some stdin!

We can just steal some example [event data](https://sensuapp.org/docs/latest/events#sensu-event-data)
from the official sensu documentation page.

    cat > test-data.json
    ...
    cat test-data.json | ./handler.rb

And look! The *Show* handler did what it says it does, it prints out the
settings and prints out the event data.

## Writing a Real Handler

So what kind of handler are we going to write? I toyed with the idea of
writing a trivial handler, but this time I'm actually going to take this
opportunity to write a handler that I've actually always wanted:
a "Notify My Android" handler.

Notify My Android is a service for android phones to receive arbitrary
push notifications. It is extremely easy to use. I would like to get
a NMA alert from Sensu, so let's build a handler.

Building this handler is going to be very easy thanks to this existing
[NMA rubygem](https://github.com/slashk/ruby-notify-my-android#usage-as-a-gem)

I'm just going to copy in this example to get started:

```ruby
#!/opt/sensu/embedded/bin/ruby
require 'sensu-handler'
require 'ruby-notify-my-android'

class Show < Sensu::Handler

  def handle
    NMA.notify do |n|
      n.apikey = "9d1538ab7b52360e906e0e766f34501b69edde92fe3409e9" 
      n.priority = NMA::Priority::MODERATE
      n.application = "NMA"
      n.event = "Notification"
      n.description = "Your server is under attack!!!"
    end
  end

end
```

Of course I need this gem installed, so I'm going to use the Sensu omnibus
ruby to install it:

    /opt/sensu/embedded/bin/gem install ruby-notify-my-android

## Making the Handler More Sane With Settings

Much of this will need to be replaced with real values from Sensu.
Let's start with the API key. I could certainly hard-code an API key
in here, but that would not be very flexible.

You saw in the `show` handler that we have the ability to simply read in all of
Sensu's configuration. This makes it really easy to add config for a handler!

Let's make the config file we want, and then have the handler read it:

```
cat > /etc/sensu/conf.d/notify_my_android.json
{
  "notify_my_android": {
    "api_key": "abc123"
  }
}
```

Behind the scenes I'm going to replace that with a real API key so this
will actually work of course.

But you can see how straight-forward this is, it is just a config file with
a unique top-level key. In this case the key is `notify_my_android`. It is
customary to have the name of the key be the name of your handler.

    mv handler.rb notify_my_android.rb

Now to use this config, we can just use the `settings` hash:

    n.apikey = settings["notify_my_android"]["api_key"]

So great. Really the ruby glue provided by the `sensu-plugins` gem makes
everything available to you as you need it.

## More Adjustments

We can change our application to Sensu:

    n.application = "Sensu"

What should the event key be? Probably something about what is wrong on what
host:

    n.event = @event['client']['name'] + '/' + @event['check']['name']

For the description we can use this hander [event summary](https://github.com/sensu-plugins/sensu-plugin/blob/aa59019a584eae88f3e784d7079f59a762879418/lib/sensu-handler.rb#L61)
method.

    n.description = event_summary

Well, it isn't many lines of code, but I don't think we need many? Does it it
work?

    cat event-data.json | ./notify_my_android.rb

It is kind strange to see no command line output though, that will make this
handler pretty difficult to debug when things go wrong. Let's simply print
the actual response we get back from the NMA method:

```ruby
  def handle
    response = NMA.notify do |n|
      n.apikey = settings["notify_my_android"]["api_key"]
      n.priority = NMA::Priority::MODERATE
      n.application = "Sensu"
      n.event = @event['client']['name'] + '/' + @event['check']['name']
      n.description = event_summary
    end
   puts response.inspect
  end
```

    cat event-data.json | ./notify_my_android.rb

That is better. It could be made more pretty, but at least we get something.

## Conclusion

You can see that there is really not much here, and that is because we get so much
from `Sensu::Handler` class that we are inheriting. Getting settings for our
handler, like an api key is super easy, thanks to the automatic `settings` variable
we have access to. All of these event an client variables are given to use
in a sanitized way from the standard-in, but I could imagine we could do fancier things with them.

Speaking of fancy, on my lecture on tuning alerts, remember the `refresh` and
`occurences` settings? This handler already respects those. That is part of the
filtering logic of the `Sensu::Handler` class that we inherited.

However, if you needed to you could override that method with your own, if
notify-my-android need special filtering.

But even with such little code our handler is mostly functional!
When you take the existing methods you get from the `Sensu::Handler` class
and you combine them with existing ruby gems that exist for just about
anything, you get a great combination that allows you to build new
integrations with Sensu, with very little effort.

I am by no means a "Ruby guy", but I can handle this.

So go forth and do not be afraid to build custom integrations with Sensu,
as you can see you can get very far with a very minimal product. With a
little glue, Sensu can integrate with just about anything!
