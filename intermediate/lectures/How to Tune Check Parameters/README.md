# How to Tune Sensu Check Parameters

## Anatomy of a Sensu Check Definition

Once you have Sensu setup and running in production, you need to figure out
how you are going to rate limit and throttle alerts that you get.

Say you have setup an email handler in combination with a disk check that
runs every minute. You certainly don't need an email every minute reminding
you that you are out of disk space!

This is where check tunables come in, let's talk about what they are
and how to use them.

### How Checks Are Defined

Sensu checks can be defined with lots of different attributes. Now-a-days the
Sensu
[documentation](https://sensuapp.org/docs/latest/checks#definition-attributes)
is *excellent*, and describes every possible attribute in detail.

Most of these attributes are self-explanatory, it isn't really necessary for me
to just read these two you.

But the more-interesting aspect of these check definitions are those attributes
that are *not* used by Sensu! That's right, the Sensu check definition language
is extremely flexible you can add *arbitrary* key/values in the check definition
and the Sensu core will simply ignore them, and not through a syntax error.

This is a big deal, and it means that you can extend Sensu to do really interesting
things. Let me show you a few things that become possible when you allow this kind
of arbitrary data passing.

### Sensu-plugin Attributes

Let's inspect some very popular [extra
attributes](https://sensuapp.org/docs/latest/checks#sensu-plugin-attributes)
that you can set for Sensu Handlers to use. To reiterate, these are extra
setting you can just stick in your check definition for Sensu handlers to pick
up on. Remember that Handlers are just scripts that are executed by Sensu when
events fire. If the handler you are using utilizes the `sensu-plugin` gem (and
almost every handler on the `sensu-plugins` Github project does), then they will
respect these parameters.

Let's look at a few:

#### Occurrences

Occurrences: The number of event occurrences that must occur before an event is
handled. The default is `1` here. That means by default handlers will begin to
fire on first event. So if you are running check-http, and the website goes
down, then the *first* time that check fails, the Sensu handler will do
something. To be clear here, *Sensu* is calling this handler *every time*.  For
example if you are using the mailer handler like in our examples, Sensu is just
running that mailer script every single time the check fails. *But*, the
handler will filter itself based on this `occurences` setting.

For another example, let's say that you have a ping check, but you know that
sometimes the network can be flaky, and you don't want to get an email unless
the network is *really* down. `Occurences` can be one way to gloss over these
failures. If this check has an interval of `60` seconds, and you set the
`occurrences` setting to 5, then on the fifth time this check fails on that 5th
minute, the handler will actually do something about it. If the check passes
before that 5th time, then the check will reset, and no email would have been
sent.

#### Refresh

Refresh is a time unit, in seconds, that represents the next layer of filtering.
The default refresh is 1800 seconds, which is 30 minutes. This means that you should
get 30 minutes between when the mailer handler will send you emails.

Keep in mind that this setting is independent of the `occurrences` setting. In
other words, if you have a check that runs once a minute, and an `occurrences` setting of
`15`, that means you will get an email alert 15 minutes after the check started failing.
You will then get another email on minute 30, because that is what `refresh` defaults to.
You won't get another email till minute 60.

This is probably fine, but you should just be aware of how these parameters interact.

If you don't believe me or you would like to see for yourself, you can always
look at the [sourcecode](https://github.com/sensu-plugins/sensu-plugin/blob/aa59019a584eae88f3e784d7079f59a762879418/lib/sensu-handler.rb#L108-L119)
that controls this filtering behavior.

#### Dependencies

Dependencies is a totally underutilized parameter. With dependencies you can automatically
*not* fire an email if a different check is already failing. You can even reference other
hosts with this '/' notation.

A real world example of this might be something that operates via cron, and you
know that if cron isn't running, then you don't need an alert on this thing
too. If the name of your cron check is simply `check_cron`, then you can just
add `dependencies: ['check_cron']` to your check definition. If cron is already
failing, then the alerts for the thing that depends on cron will be suppressed.
This is especially helpful with network topologies and vpns. You don't need a
billion alerts if you already know the vpn link is down. In sensu these
dependencies are so easy, compared to other monitoring systems, because they
are checks in a lazy way. It does mean that you do have to double-check your
spelling. If you mis-spell your dependency name, Sensu doesn't know and it
won't catch your typo.


### Custom check attributes

We've covered a few check tunables that you can use out of the box to help
customize your alerting experience for you and your teams. Let's take moment
to talk about taking this to a really interesting leve: custom check attributes.

Say we have a check definition on disk already:

```
{
  "checks": {
    "check_mysql_replication": {
      "command": "check-mysql-replication-status.rb --user sensu --password secret",
      "subscribers": [
        "mysql"
      ],
      "interval": 30,
      "playbook": "http://docs.example.com/wiki/mysql-replication-playbook"
    }
  }
}
```

This example is right out of the official [Sensu
Docs](https://sensuapp.org/docs/latest/checks#custom-definition-attributes) Do
you recognize any unusual check parameters? `command`, `subscribers`, and
interval are all normal parameters for a check, but what is `playbook`?
Playbook is a totally custom, random parameter that someone decided to add in
here. You know what, Sensu does *not* see this as a syntax error. It liberally
accepts check definitions as long as they are syntactically correct. Anything
extra it just passes along in the event data.

But once it is *in* the event data, handlers can see it! In fact the stock
sensu mailer handler 
[*does* intepret this parameter](https://github.com/sensu-plugins/sensu-plugins-mailer/blob/a8355875b5f732c212d5eeeb51f7188b836773e5/bin/handler-mailer.rb#L95)

The code here says, if there is a playbook defined in this check, we'll go ahead
and add it into the body of the email.

So in this way you can annotate your check definitions with extra metadata
about the check. The `playbook` field is a great example, but you could do
anything! You could add datacenter, or team name, or SLA, the limit
is only your imagination. You could either just store that in the check data,
or you could go further and adjust your handlers to use that data.

In this case, we are just printing the playbook in the email of the body,
but you could do a JIRA handler that takes in tags, or an EC2 handler that
understands AZs, or maybe a multi-tenant environment that understands
customer names. Maybe you work in a datacenter environment and you want all
alerts to have an asset tag. Maybe you have a special role that each of your
servers have, or you want servers that are in production to have a special
`prod` tag. Once you have this tool in your toolbox, a lot of very
interesting possibilities show up.

## Conclusion

Anyway, this to me is one of the more interesting aspects of Sensu that I've
never really seen in any other monitoring system. Most monitoring systems
have ways to tune how often you get an email, but not many allow arbitrary
key/values that you can use for whatever you want.

Look at the external resources section of this lecture for more interesting
examples of custom check attributes. I'll try to keep a good currated list
of creative ways to use this feature.

List:

* [mailer-handler](https://github.com/sensu-plugins/sensu-plugins-mailer/blob/a8355875b5f732c212d5eeeb51f7188b836773e5/bin/handler-mailer.rb#L95)
  using the `playbook` field and adding it to the email body
* [remediation-handler](https://github.com/sensu/sensu-community-plugins/blob/master/handlers/remediation/sensu.rb#L27-L66)
  uses a special `remediation` attribute to describe ways to programmtically
  "fix" (remediate) an alert.
* [statuspage-handler](https://github.com/sensu-plugins/sensu-plugins-statuspage/blob/b5a8c4940536c4e0f0e51d980fea278e6d4075cf/bin/handler-statuspage.rb#L30)
  Uses a custom `component_id` to automatically annotate status pages.
* [ansible-handler](https://github.com/sensu/sensu-community-plugins/blob/f807971cee35bfc59f2217073f1cca25f7236e2e/handlers/other/ansible.rb#L30)
  Takes a `playbook` attribute to execute a particular playbook
* [pagerduty-handler](https://github.com/sensu-plugins/sensu-plugins-pagerduty/blob/df80a30ce3705852c2f9eb25b6ad967b64aaa553/bin/handler-pagerduty.rb#L43)
  Understands a `pager_team` for different pagerduty Teams.
* [jira-handler](https://github.com/Yelp/sensu_handlers/blob/5743cd89e9b4b9af9c3b0a45e3ac9e0ce801e569/files/jira.rb#L10)
  Builds up `tags` for helping collect related alert tickets in JIRA.

Also I'll like to the official docs on the tunables I mentioned in the lecture
for adjusting the frequency of your alerts. They will definitely come in handy
and any production Sensu engineer needs to have a firm grasp of them and
what they do.
