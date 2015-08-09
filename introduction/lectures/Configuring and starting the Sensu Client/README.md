== Configuring The Sensu Client

Remmeber that for this introduction we are installing the Sensu-Client on the same host as the Sensu-Server.

=== Starting config

Lets get a starting configuration per the official docs:

    sudo wget -O /etc/sensu/conf.d/client.json http://sensuapp.org/docs/0.20/files/client.json
    vim /etc/sensu/conf.d/client.json

Note that we have added the "test" tag into the `subscriptions` array, this is the same tag we used on the pervious lecture where we configured the Sensu-server to run that check-memory check.

Name is the name of the server, usually you might use the fqdn. Address is actually a free-form field, an ipv4 address or whatever you want to use is actually fine.

Remember the client puts things onto rabbitmq. The Sensu server doesn't actually need IP connectivity to the client at all.

=== Check Dependencies

Remember when we configured the Sensu Server to run that check-mem script in the previous lecture? We didn't even bother to install the actual check script. Why? Remember that checks are always executed by the Sensu-client. This Sensu client we are configuring is going to need this check, so lets get it:

    sudo wget -O /etc/sensu/plugins/check-mem.sh http://sensuapp.org/docs/0.20/files/check-mem.sh
    sudo chmod +x /etc/sensu/plugins/check-mem.sh

=== Client startup

Now lets startup the client:

    sudo /etc/init.d/sensu-client start

And tail the logs

    sudo tail -f /var/log/sensu/sensu-client.log

or if you feel fancy with `jq`:

    sudo tail -f /var/log/sensu/sensu-client.log | jq .

=== Note on other config files

Remember that the sensu client talks to RabbitMQ? We are actually taking advantage of the fact that we already have a rabbitmq.json file available for the sensu-client to use.

If you were installing the Sensu-client on a different server, you would also need that rabbitmq configuration file deployed there. But that is pretty much all you need for a client.
