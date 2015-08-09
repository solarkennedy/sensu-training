== Installing Redis

If you remember from the architecture lecture, Redis is where Sensu stores its long term state.
While this may seem an extra component to install at first, it is the one of the
key things that enables Sensu to scale, because with Redis, none of the Sensu
servers need to store any state, so you can have as many as you need. But
we'll talk about that in more advanced courses.

If you already have a Redis installation to use, you can certainly use that instead,
but here we will be installing a very basic Redis instance.

=== Installation

    sudo apt-get update
    sudo apt-get -y install redis-server

=== Starting

Now lets start it up:

    sudo update-rc.d redis-server defaults
    sudo /etc/init.d/redis-server start

=== Logs and Confirmation

    redis-cli ping
    cd /var/log/redis
    tail redis-server.log

By default you are going to get some sane defaults, only binding on local host on tcp port 6379:

    netstat -anptu | grep redis
 
