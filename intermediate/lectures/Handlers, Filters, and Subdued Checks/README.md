# Handlers, Filters, and Subdued Checks

Let's talk about filters. Eventually when you scale out any monitoring system,
you come to the conclusion that not all alerts are created equal. Sensu's
filter language is one tool you have to describe certain policies, to filter
out certain alerts. 

## How Filters Work

It should be noted that Sensu filters can only filter things **out**. You
define the set of rules you want to use, to select which events should be
ignored:

    https://sensuapp.org/docs/latest/getting-started-with-filters#create-an-event-filter

The official documentation on this subject is actually really good, so I don't
feel the need to go over this subject too much, but I think it is worth doing
an example.

The first thing you need to understand about filters, is that they always
operate on *event data*. Let's look at some example event data to refresh our
memories:

    https://sensuapp.org/docs/latest/events#sensu-event-data

There are lots of interesting things in this dictionary to use for filters.

Let's look at the example in the docs:

    https://sensuapp.org/docs/latest/getting-started-with-filters#inclusive-filtering

 You can see that filters are defined in the `filters` configuration namespace,
then next is the name of the filter, in this case the name of the filter is
`production`. Look at the next key, `attributes`. Here we are defining the
attributes of the *event data* that are relevant for filtering. Next is
`client`, so this filter has something to do with the client section of the
event data, and then `environment: production`. But.. I don't see `environment
in our example event data:

    https://sensuapp.org/docs/latest/events#sensu-event-data

### Custom Client Attributes

This hints on a topic that we haven't really covered, and that is: Custom
client attributes. Remember in the lecture about turning Sensu checks, we said
that you can add custom data into the check for handlers to use? These were
things like "playbook", and if the "playbook" key was in the check definition,
the email handler would see that and stick it in the email output. 

In the same way that you can define custom check attributes, you can also
define custom client attributes:

    https://sensuapp.org/docs/latest/clients#custom-definition-attributes

Any custom fields here will be ignored by Sensu and just passed on to handler
and filters for use. The example in the docs here is for MySQL, but
`environment` is a good one too. Annotating your clients with metadata likes
this means that handlers and filters can use it. Let's take our client on this
test server and annotate it with `environment: production`.

    cd /etc/sensu/conf.d
    vim client.json

And now let's restart the sensu-client to pick up that change:

    sudo restart sensu-client

Sensu pretty much will just ignore this extra data, it is not a syntax error.

Now our filter kinda makes more sense. It filters out anything with
`environment: production` in the client section of the event data.

Well we just made our local client have this production attribute, let's apply
this filter and see if we can filter it out.

```
{
  "filters": {
    "production": {
      "attributes": {
        "client": {
          "environment": "production"
        }
      }
    }
  }
}
```

Filters are consumed by the sensu-server, so we have to restart the sensu
server to pick up on it.

    sudo restart sensu-server

Now, is our the checks being filtered?

    tail -f /var/log/sensu/sensu-server.log

It isn't. Why not? Because we haven't told sensu to connect the pieces between
this filter we created, and the handler that is executed. In this case, it is
our mailer handler. We need to tell our mailer handler to use the filter we
created, so that we don't get emails for things in the production environment.

```
"filters": ["production"]
```

Note here that I'm calling out this filter by name, and "production" was the
arbitrary name of the filter. Now we should restart the sensu server one more
time, and then see if it worekd.

    https://sensuapp.org/docs/latest/filters

## Subdue

The "Subdue" mechinism is another tool that you can use, to quiet certain
checks during specific time period. This is useful for checks during what you
might call "quiet hours":

    https://sensuapp.org/docs/latest/checks#subdue-attributes

The subdue mechansim works really well when used at the publisher level. This
means that the checks are never even initiated by clients in the first place,
you are not just silencing alerts.

All of the subdue attributes are time-centric, they don't have anything to do
with client attributes. Also you should note that this kind of filtering is on
a per-check basis, they are not tied to a particular client or client
attribute.

This is not quite the same as filter, but it kinda acts like one, so I figured
I would mention it. Sometimes you just want to subdue checks that are not
relevant to check during say, non business hours. Other times you want to
filter our checks that operate on custom client or check attributes, like
things that are in the production environment.

