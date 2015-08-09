== Installing Sensu Itself

=== Repos

Like many projects, Sensu provides packages and repos to make it easy to install.

Here we'll install the Debian package repos per the docs:

    wget -q http://repos.sensuapp.org/apt/pubkey.gpg -O- | sudo apt-key add -
    echo "deb     http://repos.sensuapp.org/apt sensu main" | sudo tee /etc/apt/sources.list.d/sensu.list
    apt-get update


=== Actually Installing It

Now that we have the repo installed and up to date, we can actually install the Sensu package.

    apt-get install sensu

=== About the package

As an engineer, you need to know that the Sensu package itself is in "omnibus" form, which means it contains everything it needs to run, including its own ruby interpreter. The same package can function as a Sensu Client, or Server, or API.

Lets look a bit at the package contents:

    dpkg -L sensu | less

You can see some example config files, a README in that conf dir, lets check that out next.

Lots of stuff in /opt/sensu/embedded, that is the embedded ruby and gems. It does make the package bigger, but is sure makes easier to deploy, especially considering all the strange and old system rubys that exist everywhere. I promise, you will learn to love the omnibus package.

Lets take a look at that readme:

    vim /etc/sensu/conf.d/README.md

You will eventually pick up here that Sensu's configuration is JSON in /etc/sensu/conf.d. 

True story, Sensu reads in all the json in these directories recursively and then does a big merge. So the filenames are actually irrelevant. The JSON format should be a hint to you that it is designed for a computer program to spit out these files, aka a configuration management tool. While out of the scope of this introductory video, using configuration management is highly recommended, it is pretty easy for us humans to make mistakes writing out json.

=== Configuring Sensu Server

I'm going to use the same instructions from the official documentation for this introduction, and talk a little bit about what is going on behind the scenes.

Lets download the starter sensu-server config file:

    wget -O /etc/sensu/config.json http://sensuapp.org/docs/0.20/files/config.json
    vim /etc/sensu/config.json

You can see for this example we are running all of these components on localhost on the same server. That is fine for this example. You can see some of Sensu's flexibility here, as you can scale out the components by scaling each in their own way, splitting out things to different hosts, etc. But for most installations, having everything on one host is just fine.

=== Installing the First Check

We are going to go ahead and follow the official docs and install a memory check:

    wget -O /etc/sensu/conf.d/check_memory.json http://sensuapp.org/docs/0.20/files/check_memory.json
    vim /etc/sensu/conf.d/check_memory.json

As hinted in the early architecture lecture, this is a "subscription" check, as you can tell because there are subscribers in that array, and there is no "standalone" key. (on standalone checks there would be a standalone: true) So this will be a check that will be executed by the client, but requested by the server. It just so happens the client and server on the same machine here.

=== Configuring a handler

If you remember from the first lecture, Handlers are the things that the sensu Server runs in response to Events. They are just scripts that read event data in json form from stdin and then do *something*. In this example we are just going to install a very trivial handler, "cat":

    wget -O /etc/sensu/conf.d/default_handler.json http://sensuapp.org/docs/0.20/files/default_handler.json
    vim /etc/sensu/conf.d/default_handler.json

Can you imagine in your head what this handler will do when it gets event data? Thats right, it will just, spit the same thing back out again? Where will it spit it out? Well, not pagerduty or anything, but just in the Sensu-server log. Remember that the Sensu Server is responsible for executing handlers.

We'll see it in action in a bit.

=== Big Chown

    sudo chown -R sensu:sensu /etc/sensu

Just in case we made a mistake as root and sensu can't read any of these files.

=== Start The Server and API

Lets start up the sensu server and the api component and check it out:

    sudo /etc/init.d/sensu-server start
    sudo /etc/init.d/sensu-api start

You can see how its doing:

    tail -f /var/log/sensu/sensu-server.log
    tail -f /var/log/sensu/sensu-api.log

The Sensu logs can be a little tricky to parse, as they themselves are in json format. Sometimes I like to use the `jq` command to make it a little prettier:

    tail -f /var/log/sensu/sensu-server.log | jq .

`jq` deserves a whole course in itself. Maybe I'll make a `jq` course... But for now `jq .` is good printing jq command to know.
