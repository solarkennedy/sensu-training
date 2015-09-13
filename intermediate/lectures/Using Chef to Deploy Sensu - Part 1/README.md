## Using Chef to Install and Configure Sensu

### Introduction

In this lecture we will use Chef to install and configure Sensu.
Like any configuration management tool, the purpose of this is to
be able to reproduce our work, and encode how to get from a blank
server, to a fully working Sensu installation.

In this lecture I'm going to just use the chef-solo, 
but it would be very similar to a production setup where you
have Chef-server or whatever.

### Getting Chef

I'm going to download the latest version of chef, because before I saw some
incompatibilities with earlier versions of chef and the cookbooks I'm going
to be using

    sudo su -
    wget https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/10.04/x86_64/chef_12.4.1-1_amd64.deb
    dpkg -i chef_12.4.1-1_amd64.deb && rm chef_12.4.1-1_amd64.deb 


### Initial Setup

Now I'm going to setup the standard chef-repo directory structure:

    mkdir chef-repo && cd chef-repo
    mkdir cookbooks
    mkdir .chef
    vim solo.rb
    file_cache_path "/root/chef-solo"
    cookbook_path "/root/chef-repo/cookbooks"
    vim .chef/knife.rb
    file_cache_path "/root/chef-solo"
    cookbook_path "/root/chef-repo/cookbooks"

The official way to download cookbooks is using the knife tool, which uses
git under the hood, so we have to make a simple git repo.

    cd cookbooks
    apt-get -y install git

    git init
    git config --global user.email "root"
    git config --global user.name "root"
    git commit -m "First Commit" --allow-empty

### Installing the required cookbooks

Let's take a look at the cookbooks we are going to use. The major one
is of course, [Sensu](https://github.com/sensu/sensu-chef).

For the purposes of this lecture I'm actually going to skip SSL configuration.

Looking through the provided recipes, it looks like we are going to need
to include `sensu::default` first. And then for configuring a server we
are going to need `rabbitmq`, `redis`, `server_service`, and `api_service`.
We'll install a client and a dashboard a bit later.

I'm hoping to get away with most of the sane default here, but these attributes
will become important to you as you actually integrate Sensu with your
existing chef infrastructure.

Let's get the cookbook and its dependencies so we can use it using
the knife tool:

    knife cookbook site install sensu
    ...
    ls

Look at all of these cookbooks we didn't have to write!

### Making our `sensu_server` wrapper cookbook

But we will need to write at least one "wrapper" cookbook to kinda put things
together for us. I'm going to call this first wrapper cookbook, `sensu_server`:

    knife cookbook create sensu_server

Now let's begin to put together our first `sensu_server` recipe and try to put
all these pieces together. First let's include that default recipe the documentation
said we need to include:

    include_recipe "sensu::default"

Now lets try to include all the other components that normally go on the Sensu server:

    include_recipe "sensu::rabbitmq"
    include_recipe "sensu::redis"
    include_recipe "sensu::api_service"
    include_recipe "sensu::server_service"

Now let's use chef-solo and see what happens. I'm going going to make a role or anything,
I'll just run this cookbook directly

    chef-solo -o sensu_server --config solo.rb

What do we get? Our first error:

    Chef::Log.debug 'apt is not installed. Apt-specific resources will not be executed.' unless apt_installed?

Kinda strange. Of course apt is installed, but this is chef telling us that we have to
let it know that we need apt. But really we only need to include the sensu
cookbook as a dependency of our wrapper:

    vim cookbooks/sensu_server/metadata.rb
    depends 'sensu'
    chef-solo -o sensu_server --config solo.rb

Our next error is about databags:

     40>>         raw_hash = Chef::DataBagItem.load(data_bag_name, item)

By default the sensu cookbook uses databags to share ssl certs
between clients and servers. For the purposes of this lecture
I'm not going to go through this particular procedure, so I'm just
going to set the attribute to disable ssl for now, just like we
were actually doing in all the previous examples.

    vim cookbooks/sensu_server/attributes/default.rb
    default["sensu"]["use_ssl"] = false
    chef-solo -o sensu_server --config solo.rb

Wow, lots of stuff. But now you can see the sensu things are running:

    ps -ef --forest

## Installing a Client

A lone Sensu server is no fun, let's also make sure there is a client ready to do stuff:

    vim cookbooks/sensu_server/recipes/default.rb

    sensu_client 'localhost' do
      address '127.0.0.1'
      subscriptions []
    end
    include_recipe "sensu::client_service"

Now we can apply it

    chef-solo -o sensu_server --config solo.rb

And you can see it is running, although we haven't configured any checks.

## Installing Uchiwa

Let's install a dashboard so we can visually see what is going on with Sensu.
To do that we'll need the [Uchiwa cookbook](https://github.com/sensu/uchiwa-chef):

    knife cookbook site install uchiwa

Now we can add this to our recipe:

    vim cookbooks/sensu_server/recipes/default.rb
    include_recipe "uchiwa"

Now we will need to make sure our `sensu_server` wrapper depends on it:

    vim cookbooks/sensu_server/metadata.rb
    depends 'uchiwa'
    chef-solo -o sensu_server --config solo.rb

Opening it in a browser:

   xdg-open http://localhost:3000

We have a login page because the default chef attributes setup
a username of `admin` and a password of `supersecret`

    https://github.com/sensu/uchiwa-chef/blob/master/attributes/default.rb
