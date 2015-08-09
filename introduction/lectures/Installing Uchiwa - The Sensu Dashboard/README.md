## Installing Uchiwa

Sensu doesn't come with a dashboard. Surprised? You should not be.

It is refreshing to me that Sensu *doesn't* presume to provide a dashboard and
that the API is well-formed enough to provide all the endpoints necissary for
an external dashboard or any other external tool to work.

In other words, Sensu's de-coupling philosophy means that you can use *any*
dashboard, or none, or whatever. If you have some super fancy in-house
dashboard that you already have and you want to integrate? Go for it.

For most people, the very popular Uchiwa Sensu dashboard will work just fine.
Let's install that.

### Actually Installing It

The official docs references two different dashboards here, "Uchiwa" and the "Sensu Enterprise Dashboard". The Enterprise dashboard is a version of Uchiwa that does fancier authentication and that sort of thing.

For an introductory course, we are going to use the Open Source dashboard, Uchiwa. It works fine for most people. I'll cover the differences between the open source and enterprise versions of everything in a later lecture. But, Uchiwa for now.

Uchiwa is available from the same Sensu repositories that you have enabled from previous steps:

    sudo apt-get -y install uchiwa

### Configuring Uchiwa

Lets look at the config file it dropped in for us:

    vim /etc/sensu/uchiwa.json

Uchiwa is designed to be multi-site aware. This is an advanced topic, but it is good to know that you can use Uchiwa to aggregate multiple sensu endpoints.

For use we only need our local site:

```
{
  "sensu": [
    {
      "name": "Site 1",
      "host": "localhost",
      "port": 4567,
      "timeout": 5
    },
  ],
  "uchiwa": {
    "host": "127.0.0.1",
    "port": 3000,
    "interval": 5
  }
}
```

Caution here: Note that I changed the default away from binding on every ip, and set it to localhost only. Be sure not to accidentally expose an un-authenticated dashboard to the whole world.

And lets restart uchiwa to pickup those changes:

    /etc/init.d/uchiwa restart

### Looking at the Dashboard

If we got everything right, then we should be able to load it up.

    ssh -L 3000:localhost:3000 root@server
    xdg-open http://localhost:3000

### Why didn't it work?

Well, it didn't work, lets do some basic trouble-shooting.

First, is the thing running?

     ps -ef | grep uchiwa

Nope. How about the logs:

    cd /var/log/
    tail uchiwa.log
    tail uchiwa.log | jq .

Invalid charater. Remember when I said that writing json was for computers?

    vim /etc/sensu/uchiwa.json
    /etc/init.d/uchiwa start
    ps -ef | grep uchiwa

### Now load it

    xdg-open http://localhost:3000

