# Hardening the Rest of Sensu

If you are running Sensu in production, you need to be at least aware of
Sensu's attack surface is, from a security prospective. Obviously different
environments warrant different levels of security precautions. Even if you
don't do anything about all of pieces, you should at least be informed.

## RabbitMQ

We talked before about using SSL with RabbitMQ to encrypt communication between
RabbitMQ and the other components. You should know that by default RabbitMQ
does come with a guest account, even though it can only be used locally. In a
production environment you should probably remove the guest account, and ensure
that the Sensu credentials are strong.

If you can, I recommend firewalling off everything except the SSL port. The SSL
port 5671, is the only port the Sensu components need to use.

## Redis

The only thing that needs to talk to Redis is the Sensu-server and Sensu-API
components. If possible, try to lock down the access to the redis port to only
those things that need it. Do not expose Redis to the internet.

If you absolutely must use untrusted networks to communicate with Redis, it is
advised to use stunnel or a vpn to encrypt your traffic.

## Sensu API

The Sensu API has a web interface, and should obsolete not be exposed to the
outside world. The Sensu-api configuration has settings for enabling http-basic
auth, and you can a SSL terminating webserver like nginx in front, to encrypt
any traffic that goes to the api.

Don't forget that if you do enable authentication and SSL on the Sensu API, any
tool that utilizes the API will need to be updated to use SSL and
authentication.  This means at least the dashboard configuration will need to
be updated.

## Dashboards

The Sensu dashboard is another http endpoint that can use hardening. Just like
most web frontends, it is recommend to put SSL termination in front, and of course
use some sort of authentication.
