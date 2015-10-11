# Securing RabbitMQ With SSL

Let's talk a bit about why we care about SSL with RabbitMQ. In Sensu, RabbitMQ
is the primary way that messages are sent between the client and servers. This
whole time we have not been using SSL, which means all traffic between the
Sensu client and server has been unincrypted. This is a potetial security risk,
espcially if you are going across untrusted networks. This is especially
important if you are not useing `safe_mode`, and the Sensu clients will execute
arbitary code upon a check request.

SSL encrypts this traffic. But, enabling SSL means we have an additional burden
of getting SSL certs. For this lecture we will be creating our own certificate
authroity and issuing our own self-signed certs. At the end of the lecture I'll
discuss the pros and cons to this approach, and talk about some other options.

## Making a CA, Signing Some Certs

The official Sensu documentation actually comes with some helping scripts
to create our own Certificat Authority and sign our own certs.

    https://sensuapp.org/docs/latest/ssl

The docs are a little sparse, but let's download the helper script and
see how far we can get...

    cd /tmp && wget http://sensuapp.org/docs/latest/tools/ssl_certs.tar && tar -xvf ssl_certs.tar
    cd ssl_certs
    ls
    vim ssl_cert.sh
     && ./ssl_certs.sh generate

....

## Adding Certs to RabbitMQ

Now that we have some certs and keys to work with, let's copy
them into RabbitMQ's config directory for use:

    cp server_key.pem server_cert.pem cacert.pem /etc/rabbitmq/ssl/

Now we can configure RabbitMQ to use them:

```
[
    {rabbit, [
    {ssl_listeners, [5671]},
    {ssl_options, [{cacertfile,"/etc/rabbitmq/ssl/cacert.pem"},
                   {certfile,"/etc/rabbitmq/ssl/cert.pem"},
                   {keyfile,"/etc/rabbitmq/ssl/key.pem"},
                   {verify,verify_peer},
                   {fail_if_no_peer_cert,true}]}
  ]}
].
```

    /etc/init.d/rabbitmq-server restart

## Adding Certs to Sensu

    cp server_key.pem server_cert.pem cacert.pem /etc/sensu/ssl/

    vim /etc/sensu/conf.d/rabbitmq.json

```
  "rabbitmq": {
    "ssl": {
      "cert_chain_file": "/etc/sensu/ssl/cert.pem",
      "private_key_file": "/etc/sensu/ssl/key.pem"
    },
    "host": "localhost",
    "port": 5671,
```

Remember both the Sensu server, client, and API connect to RabbitMQ for
communication, so they will all need to be restarted to pick up this
configuration:

    sudo restart sensu-client
    sudo restart sensu-server
    sudo restart sensu-api

Take note here that port 5671 is the port for SSL, 5672 is the non-ssl port.
Both RabbitMQ needs to be listening on that port and Sensu needs to be
configured to connect to that port.

## Alternatives

Setting up SSL can be a pain, but once you have it setup, it is done. I don't
mind so much that it requires this effort up front and Sensu doesn't do it
automatically for you. Honestly, I wouldn't want Sensu to do it magically for
me, just like I wouldn't want Apache or Nginx to setup SSL certs for me.

The fact that it is self-signed also doesn't bother me too much, is isn't like
someone is going to see this in a browser.

Alternativly though, if you already have a self-signed SSL cert setup in your
environemtn, say for an existing setup like Puppet or Chef, you could totally
use that. You already have a certificat authority, and each server has it's own
signed private key, it would totally work.

On the other hand, you may want to just go through the work of setting up a
different SSL cert for Sensu, just so you don't risk the possibility of breaking
your monitoring *and* your configuration managment at the same time.

SSL adds extra protection to the actual traffic on the wire for Sensu, and I
think it is absoluety worth it for any production environment. The transition
to using SSL can be abrupt and cause pain, so if you are thinking of doing SSL
eventually, I recommend doing it sooner rather than later to minimize the
disruption. Of course I always recommend using a configuration managment tool
like Chef/Puppet/Salt/Ansible, to make it easy to deploy this configuration
in a reproduceable way.

As always, look to the external resources section of this lecture for links to
the official documentation on how to configure SSL with RabbitMQ for Sensu, as
well as the exact commands I ran, and links to more tutorials for doing this
procedure.
