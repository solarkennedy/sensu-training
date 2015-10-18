# Hardening the Rest of Sensu

If you are running Sensu in production, you need to be at least aware of
what Sensu's attack surface is, from a security prospective. Obviously different
environments warrant different levels of security precautions. Even if you
don't do anything about all of pieces, you should at least be informed.

In this lecture I'll discuss some potential places where Sensu's security
footprint can be improved, although I won't actually be demonstrating
how to do so.

## RabbitMQ

We talked before about using SSL with RabbitMQ to encrypt communication between
RabbitMQ and the other components. You should know that by default RabbitMQ
does come with a guest account, even though it can only be used locally. In a
production environment you should probably remove the guest account, and ensure
that the Sensu credentials are strong.

If you can, I recommend firewalling off everything except the SSL port. The SSL
port 5671, is the only port the Sensu components need to use.

Configuring RabbitMQ and Sensu to talk over SSL actually is demonstrated in
a separate lecture.

## Redis

The only thing that needs to talk to Redis is the Sensu-server and Sensu-API
components. If possible, try to lock down the access to the redis port to only
those things that need it. Do not expose Redis to the internet.

If you absolutely must use untrusted networks to communicate with Redis, it is
advised to use stunnel or a vpn to encrypt your traffic.

Redis does store things like silences and previous check output, which could
potentially store secrets.

## Sensu API

The Sensu API is an http interface, and should not be exposed to the outside
world unprotected. The Sensu-api configuration has settings for enabling
http-basic auth, and you can a SSL terminating webserver like nginx in front,
to encrypt any traffic that goes to the api.

Don't forget that if you do enable authentication and SSL on the Sensu API, any
tool that utilizes the API will need to be updated to use SSL and
authentication.  This means at least the dashboard configuration will need to
be updated.

## Sensu Client

The Sensu client by default exposes port 3030 on localhost only, for pushing
external event data. If an attacker got on the local host, they could potentially
send arbitrary check results, potentially DOS'ing your infrastructure. I'm not
currently aware of a way to disable the client socket, but it is a potential
attack vector. Again the attacker would have to have access to localhost.

## Sensu Server

The Sensu server has no externally facing endpoint.

## Dashboards

The Sensu dashboard is another http endpoint that can use hardening. Just like
most web frontends, it is recommend to put SSL termination in front, and of course
use some sort of authentication.

The stock Uchiwa dashboard has very basic authentication, and the enterprise
dashboard has more fancy authentication. Either way, an SSL-terminating
webserver should be placed in front of the dashboard. Alternatively you can make
the SSL-terminating webserver, say, apache or nginx, do authentication for you.


## Conclusion

The general philosophy here is defense in depth: use firewalls, authentication,
and encryption where possible.

Luckily Sensu uses existing components and traditional HTTP endpoints, which
have existing, well-known best-practices for securing them.
