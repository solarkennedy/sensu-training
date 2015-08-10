== Using Puppet With Sensu

=== Intro

If you use Puppet in your environment, or you would like it, I have some good news: Puppet plus Sensu is a pretty good combination.

https://github.com/sensu/sensu-puppet
https://github.com/Yelp/puppet-uchiwa

=== Getting Started

I'm not going to run puppet in full client-server mode for this lesson. There is plenty of other documentation on that, for this lecture I'm just going to focus on Sensu-specific stuff.

This server that I'm on is freshly imaged, I have not tricks up my sleeve here. Everything will be from scratch.

Every external puppet module I use and code samples or fragments will be available in the external resources section, so don't worry about missing an exact command or try to copy paste from the video.

In fact, if things change, and they do change, I'm much more likely to keep the external resources section up to date, and not re-record the video, so just keep that in mind.

=== RabbitMQ

Just like in the Introduction lecture, the first thing I want to get in place is RabbitMQ.
To do that, I'm going to install the official Puppetlabs RabbitMQ module:

    puppet module install puppetlabs/rabbitmq

If you have never used the puppet module tool like that before, it just gets the latest release of the rabbitmq module from the puppet forge and makes it available for use. I don't have to know much about how it works, I just have to know how to interface with it in my puppet code.

    vim server.pp

```puppet
class {'::rabbitmq':
  interface => '127.0.0.1',
  delete_guest_user => true,
}
#TBD USERS
```
