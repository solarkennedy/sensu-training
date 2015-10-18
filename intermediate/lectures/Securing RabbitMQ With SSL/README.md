# Securing RabbitMQ With SSL

Let's talk a bit about why we care about SSL with RabbitMQ. In Sensu, RabbitMQ
is the primary way that messages are sent between the client and servers. This
whole time we have not been using SSL, which means all traffic between the
Sensu client and server has been unencrypted. This is a potential security risk,
especially if you are going across untrusted networks. This is especially
important if you are not using `safe_mode`, and the Sensu clients will execute
arbitrary code upon a check request.

SSL encrypts this traffic. But, enabling SSL means we have an additional burden
of getting SSL certs. For this lecture we will be creating our own certificate
authority and issuing our own self-signed certs. At the end of the lecture I'll
discuss the pros and cons to this approach, and talk about some other options.

## Making a CA, Signing Some Certs

The official Sensu documentation actually comes with some helping scripts
to create our own Certificate Authority and sign our own certs.

    https://sensuapp.org/docs/latest/ssl

The docs are a little sparse, but let's download the helper script and
see how far we can get...

    cd /tmp && wget http://sensuapp.org/docs/latest/tools/ssl_certs.tar && tar -xvf ssl_certs.tar
    cd ssl_certs
    ls
    vim ssl_cert.sh
    ./ssl_certs.sh generate
    find

As you can see the script has generated some certs and keys for us to use, including
one for a server, a client, and the CA. The are not anything really fancy, just basic
self-signed certs:

    openssl x509 -in server/cert.pem -text -noout
    openssl x509 -in client/cert.pem -text -noout

## Adding Certs to RabbitMQ

Now that we have some certs and keys to work with, let's copy
them into RabbitMQ's config directory for use:

    mkdir /etc/rabbitmq/ssl
    cp server/key.pem server/cert.pem sensu_ca/cacert.pem /etc/rabbitmq/ssl/

Now we can configure RabbitMQ to use them. I'm for refererence, the
[RabbitMQ documentation page](https://www.rabbitmq.com/ssl.html)
has exact instructions on how to enable SSL listeners:

    cd /etc/rabbitmq
    find
    vim rabbitmq.config

```
    {rabbit, [
    {ssl_listeners, [5671]},
    {ssl_options, [{cacertfile,"/etc/rabbitmq/ssl/cacert.pem"},
                   {certfile,"/etc/rabbitmq/ssl/cert.pem"},
                   {keyfile,"/etc/rabbitmq/ssl/key.pem"},
                   {verify,verify_peer},
                   {fail_if_no_peer_cert,true}]}
  ]}
```

    /etc/init.d/rabbitmq-server restart

And let's look at the logs:

    tail -f /var/log/rabbitmq/rabbit@vagrant-ubuntu-trusty-64.log

You can see that we haven't adjusted Sensu's configuration yet, so those clients
are still connecting to the non-ssl port, 5672.

## Adding Certs to Sensu

Now that RabbitMQ is listening and ready to accept SSL connections on 5671,
we are ready to give client certs to Sensu and adjust its configuration:

    cd /tmp/ssl_certs/
    mkdir /etc/sensu/ssl/
    cp client/key.pem client/cert.pem sensu_ca/cacert.pem /etc/sensu/ssl/
    vim /etc/sensu/config.json

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

    /etc/init.d/sensu-client restart
    /etc/init.d/sensu-server restart
    /etc/init.d/sensu-api restart

This config file is shared by all three on this host, in practice you might
have different components on differnet hosts, and they will all need this
treatment. Let's look at the RabbitMQ log:

    tail -f /var/log/rabbitmq/rabbit@vagrant-ubuntu-trusty-64.log

Now you can see connections are coming in on port 5671. And let's verify that the
Sensu components are still connected:

    tail /var/log/sensu/sensu-server.log  -n 200

And that uchiwa still works:

    http://localhost:3000/#/datacenters

So we did it, we got Sensu and RabbitMQ to talk over SSL, with no downtime.
Normally I would do something where I would enable SSL on RabbitMQ, disable
non-ssl, watch Sensu fail, then enable SSL on Sensu to watch it work again.
But in this case I wanted to demonstrate that this configuration change can
be done in a production environment with no downtime, as long as the steps
are followed in this order.

## Alternatives

Setting up SSL can be a pain, but once you have it setup, it is done. I don't
mind so much that it requires this effort up front and Sensu doesn't do it
automatically for you. Honestly, I wouldn't want Sensu to do it magically for
me, just like I wouldn't want Apache or Nginx to setup SSL certs for me.

The fact that it is self-signed also doesn't bother me too much, is isn't like
someone is going to see this in a browser.

Alternatively though, if you already have a self-signed SSL cert setup in your
environment, say for an existing setup like Puppet or Chef, you could totally
use that. You already have a certificate authority, and each server has it's own
signed private key, it would totally work.

On the other hand, you may want to just go through the work of setting up a
different SSL cert for Sensu, just so you don't risk the possibility of breaking
your monitoring *and* your configuration management at the same time.

SSL adds extra protection to the actual traffic on the wire for Sensu, and I
think it is absolutely worth it for any production environment. Of course I
always recommend using a configuration management tool like
Chef/Puppet/Salt/Ansible, to make it easy to deploy this configuration in a
reproducible way.

As always, look to the external resources section of this lecture for links to
the official documentation on how to configure SSL with RabbitMQ for Sensu, as
well as the exact commands I ran, and links to more tutorials for doing this
procedure.
