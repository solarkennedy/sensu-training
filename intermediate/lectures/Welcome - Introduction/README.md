== Welcome

Hi, welcome and thank you for enrolling in my course on Intermediate Sensu.

For this course, I'm going to assume you know the basics. If you haven't
taken my previous Introduction to Sensu course, please take it first.
The Introductory course will lay the groundwork for the ideas and
methods I'll be using in this course. It really is important to have a
solid mental model of how sensu works, so please take it first.

== Course Outline

What should you expect from this course?

=== Configuration Management

First, configuration management.

Config management is near and dear to my heart. It is the key to getting
reproducible configuration for any system, and Sensu is no different. I'll
cover all the popular configuration management systems.

In my opinion, if you can't rebuild your infrastructure from a git repo
and a tool, you are doing it wrong. I'll show you how to build Sensu clusters
from scratch using configuration management.

=== Utilizing third-party Check plugins and Handlers

External check plugins and handlers provide a lot of value to Sensu, but they
don't come installed out of the box.

In the intro class I showed how to install check plugins and handlers from
Github. I'll cover this in more depth and actually show you how to make your
own.

Eventually with any monitoring system you will find yourself needing to make
your own custom check script, and maybe even your own Sensu handler. I'll
show you how to make both, from scratch.

=== More advanced event routing

If you are going to run Sensu in production, it means you need real actionable
alerts. For example sending your important alerts to Pagerduty and sending
other things to email, or setting up aggregation checks across a fleet of
webservers. I'll cover this sort of event routing. And I'll talk about how
to tune Sensu to prevent alert floods and not spam your team.

=== Security

Having a production Sensu environment implies that it is secure. So I'll cover
adding SSL to the transport and point out other places to harden Sensu or other
common security gotchas you might encounter building out your Sensu
infrastructure.

== Conclusion

There are lots of things covered in this course. You can think of it as
"accelerated experience", where you get to see what it takes to run Sensu
in a real life environment, but in course form :)
