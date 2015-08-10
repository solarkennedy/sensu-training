## Open Source Versus Enterprise

I am not an employee of Heavy Water.

To be honest I have never used the Enterprise version of Sensu, but for an
introductory video I do think that it is worth talking about. Not everyone has
a crack team of engineers who are ready to take a framework like Sensu and
integrate it with all of your infrastructure.

### Differences

The number one thing you are getting when you buy something like this instead
of using the Open Source version is the Support. If you can't figure out how to
get Sensu to work, you can call a real person on the phone and get someone who
knows what they are talking about on the other end. This to me is the biggest
difference between using the Open Source version of Sensu and using the
Enterprise version.

There are some technical differences, many of which have to do with the
dashboard and security. If these features are important to you, it is worth
taking a look. Otherwise all the other differences end up being how "turn-key"
of a solution Sensu is to you. Many of these other features are doable, they
just take additional work. In the open source version, you have to go get the
Pagerduty handler yourself, where as with the Entperprise version, it is
included with the package.

### Exact Differences

This is not a sales pitch, but any engineer building a system should at least
be informed about the differences so you can make the best decision for your
situation:

* Contact routing - The enterprise version of Sensu comes with a bunch of
configured handlers to cover 90% what you might want Sensu to "do" with an
alert. The contact routing feature allows you to specify the recipient of an
alert on a per-check basis.

* Built-in thirt-party integrations - This means that the enterprise edition
come with the handlers I just mentioned. The handers are variations of
open-source versions, just more tightly integrated with the product.

* RBAC + LDAP - The Uchiwa dashboard doesn't have a concept of privlages,
it just does its thing, if you need it to be secure, it is up to you to
put it behind a web server that does authentication. The Enterprise
dashboard does this for you, but also has more fine grained controls,
like read-only mode and access to only particular datacenters.

* Support and training - Support is the key feature with the Enterprise
version of Sensu. The training is cool too, but obviously if you are
taking this course, you know that training isn't exclusive to the product,
but their training is on-site, where as this is remote.

## Conclusion

Again, like most Company Supported open source projects, the differences come
down to Support, and a bit of integration work that you don't have to do
yourself.

That is all I really wanted to say about that. It isn't that you can't roll
your own Metrics or contact routing with the Open Source version of Sensu, you
certainly can, it just doesn't come with it out of the box. For some companies,
this is a big deal, but for others they might have been looking to integrate
Sensu with their existing metrics infrastructure anyway. It just depends on
your current situation.

Nothing stops you from say, integrating Uchiwa with LDAP, but it is non-trivial
problem that you can throw money at, which is a nice option to have.
