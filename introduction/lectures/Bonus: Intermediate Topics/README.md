## Bonus: Intermediate Topics

The learning doesn't have to stop at an introduction. An intro is good, but eventually you might want to bring Sensu "into Production", and that is what the intermediate lesson is all about. I'll cover topics like:

### Using Configuration Management to configure and deploy Sensu

This is a big deal to me personally. It is one thing to test drive sensu and hand-make config files and stuff. But for the long term you want to use a tool consistently deploy sensu and checks that go with it. Then, I'll give a demo of the real power of using config management with Sensu: deploying monitoring hand-in-hand with the code that it monitors.

### Writing and Deploying your own checks and handlers *and* third-party ones

Sensu gets really powerful in a production setting when you can take advantage of the corpus of Sensu *and* nagios Plugins available at your disposal. I'll cover deployed these third-party plugins as well as designing your own to meet your own needs.

### More advanced event routing

I hinted at some of the advanced things you can do with event data, I'll cover them in the intermediate course. These are the things like Sending your important alerts to Pagerduty and sending other things to email, or setting up aggregation checks across a fleet of webservers.

### Security

Having a production Sensu environment implies that it is secure. So I'll cover adding SSL to the transport and point out other places to harden Sensu or other common security gotchas you might encounter building out your Sensu infrastructure.
