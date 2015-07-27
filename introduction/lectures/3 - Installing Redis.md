== Installing Redis

Remember that Redis is where Sensu stores its long term state.

If you already have a Redis installation to use, you can certainly use that instead, but here we will be installing a very basic Redis instance.

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
 
