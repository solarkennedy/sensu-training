## Setup and Configuring RabbitMQ


RabbitMQ is the message bus between the Sensu Server and the Sensu Client. We have to get it setup first before we can do much of anything in Sensu. Lets do it.

https://sensuapp.org/docs/0.20/install-rabbitmq

### Setup

I'm mostly going to be following the guildlines of the official Sensu documentation. RabittMQ has it's own docs and everything, but for the most part the only Sensu-specific thing is adding the vhost, user, and permissions.

For this lecture I'm going to be working on an Ubuntu server, but this would work for any system that you can install RabbitMQ on.

### Install

RabbitMQ is written in Erlang, so per the Sensu-docs recommendation, we are going to install the latest upstream version of Erlang:

    sudo wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
    sudo dpkg -i erlang-solutions_1.0_all.deb
    sudo apt-get update
    sudo apt-get -y install erlang

Now we'll install RabbitMQ:

    wget http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
    sudo apt-key add rabbitmq-signing-key-public.asc
    echo "deb     http://www.rabbitmq.com/debian/ testing main" | sudo tee /etc/apt/sources.list.d/rabbitmq.list
    sudo apt-get update
    sudo apt-get -y install rabbitmq-server

You may not technically need the latest version of RabbitMQ, like most software it is a tradeoff between using an older version from your Distro sources versus using the latest version out there on the internet. If you already have a RabbitMQ setup, of course you are free to use it instead!

### Startup

    sudo update-rc.d rabbitmq-server defaults
    sudo /etc/init.d/rabbitmq-server start

### Configure

Out of the box RabbitMQ is ready to go, but we need a vhost and user for Sensu to use:

    sudo rabbitmqctl add_vhost /sensu
    sudo rabbitmqctl add_user sensu secret
    sudo rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"

`rabbitmqctl` is the command line tools to administer RabbitMQ, and you can see we have made a Sensu user with the password of "secret", and given it permission on a RabbitMQ vhost. When we configure the Sensu client and server, we'll need these credentials and configure them in the same way.

### Extra: Logs and web interface

It is important to know at least a little bit about managing RabbitMQ, you should at least know where the logs are to troubleshoot:

    cd /var/log/rabbitmq/
    tail -f rabbit\@leb1.log

RabbitMQ also has a nice web interface you can use to see how it is doing.

You do have to enable it:

    sudo rabbitmq-plugins enable rabbitmq_management
    # In other terminal
    ssh -L 15672:localhost:15672 vagrant@localhost -p 2222 -i ~/.vagrant.d/insecure_private_key
    xdg-open http://localhost:15672
