# Writing Your Own Sensu Checks

There comes a time in every engineers' life where they have a need to
monitor something, where no existing monitoring script exists.

Luckily, writing check scripts is relatively easy, because the contract
you have to follow is so straightforward and hasn't changed for... decades?

## Your First Check Script

Let's write a very basic script in bash at first, and then we'll port it
to Ruby before it gets too complex.

For the lecture we are going to build a Sensu check to check to see if
a file exists. There are certainly existing checks like this that
already exist, but I find it helpful to do this exercise when we all
already know what this check is *supposed* to do.

But I would like to actually get my TDD on and write some tests first for
this thing:

```bash
#!/bin/bash

function assert {
  if [[ $1 -eq $2 ]]; then
    echo Pass
  else
    echo "Fail. Expected $2 but got $1"
  fi
}

touch test_file
./check_file_exists test_file
assert $? 0

rm -f test_file
./check_file_exists test_file
assert $? 2
```

So we have a little bit of a test framework to make sure our code will do
what we think it should do. On the first test case where the `test_file`
exists we assert that after the check runs the return code should be `0`,
which means "ok"

On the second case we remove the file and run our script and assert that
the return code is `2`, which means critical. If you are curious about
these return code conventions, they are pretty old and very standard:

    https://sensuapp.org/docs/latest/checks#what-are-sensu-checks

Pretty much every monitoring system that works in the linux world follows
these same conventions.

So let's run our tests!

    chmod +x test_check_file_exists
    ./test_check_file_exists

Of course our tests fail, as we haven't written any code yet. 127 is
the shell's return code when the script doesn't exist. Let's write
some code to make our tests pass.

    vim ./check_file_exists

```bash
#!/bin/bash
```

Now for for the most naive version of this check, we can simply use the
basic test functionality of the shell:

```bash
[[ -f $1 ]]
```

We this might work. In bash the final return code here will be whatever
the result of this test is. Does it pass our tests?

    chmod +x check_file_exists
    ./test_check_file_exists

It doesn't. The second test case fails because this test returns `1` when
the file doesn't exist, and we were expecting a `2`.

Maybe we can write more than one line of code and make this check a tad
more user friendly:

```
#!/bin/bash
if [[ -f $1 ]]; then
  echo "OK: File '$1' exists and is a normal file"
  exit 0
else
  echo "Critical: File '$1' doesn't exist or is not a normal file"
  exit 2
fi
```

This is a bit more readable. Let's run the tests:

    ./test_check_file_exists

Both pass now. You can see that writing Sensu checks is really not that bad,
all you have to do is conform to the return code conventions. Adding extra
output for humans is nice too. I really like it when checks return as much
human-readable friendly output as possible.

## Porting to Ruby

Bash is fine, but what if we wanted to make this check be more flexible,
and have options like "negating" the check, so it is ok if the file
*doesn't* exit?

You can do this in bash, but more complex logic is easier to do in a language
with more constructs. But guess, what: you have a language interpreter
at your fingertips that is guaranteed to be deployed with every Sensu
client that you deploy: the Sensu embedded ruby!

You get a modern version of ruby with lots of goodies.

Let's port our check to use this Ruby so we can expand it's functionality
more easily.

```ruby
#!/opt/sensu/embedded/bin/ruby
require 'sensu-plugin/check/cli'
```

Now this is a bit controversial: hard-coding the she-bang here to use
the embedded Sensu ruby is a bit inflexible. It is true. If a user
wanted to use a different ruby, they would have to literally edit
this script and modify it.

On the other hand, it is explicit about the exact ruby you are expected
to use. If you didn't have this she-bang here, a user might execute
it using the system ruby, which probably doesn't have the sensu-plugin gem
that you requested.

It is a tossup. For open-source plugins it makes Sensu to just be generic
and use whatever ruby is set in the environment, but for plugins I develop
in production, I hard-code the path because I never want it to be accidentally
run, by a machine or by a human, with the wrong ruby.

Anyway, let's run our tests just with what we've got.

    ./test_check_file_exists

    Sensu::Plugin::CLI: ["Not implemented! You should override Sensu::Plugin::CLI#run."]

So now we need to talk a little bit about this class. The `sensu-plugin` gem
comes with a lot of helpers to help build Sensu-plugins and handlers and stuff.

Here we want to build a command line check script. Here is how you use this
class to build this check:

```ruby
#!/opt/sensu/embedded/bin/ruby
require 'sensu-plugin/check/cli'

class CheckFileExists < Sensu::Plugin::Check::CLI
  def run
  end
end
```

To use this class we have to inherit from it, and have a `run` method.
This `run` method is what is invoked when someone executes it from the
command line.

    ./test_check_file_exists

    CheckFileExists WARNING: Check did not exit! You should call an exit code method.

Closer. We haven't told the check to exit properly. Let's do what it says
and use an exit code method.

What methods can we call? Well:

    https://github.com/sensu-plugins/sensu-plugin/blob/b679e239a63d7c206bada044f67f43834d44e33f/lib/sensu-plugin/cli.rb#L26

Although this is a bit meta, we can call a method for every type of exit code.
What were those exit codes again?

    https://github.com/sensu-plugins/sensu-plugin/blob/69ac44f539d07bf044eb2b1370c36230fd00524f/lib/sensu-plugin.rb#L4

Now we should have enough data to write our check:

```ruby
#!/opt/sensu/embedded/bin/ruby
require 'sensu-plugin/check/cli'

class CheckFileExists < Sensu::Plugin::Check::CLI
  def run
    filename = argv[0]
    if File.exists?(filename)
      ok "File '#{filename}' exists!"
    else
      critical "File '#{filename}' doesn't exist!"
    end
  end
end
```

This isn't supposed to be a ruby lesson, but just a demonstration of what
it looks like to write sensu checks in ruby using the standard sensu-cli
plugin constructs. It reads pretty well I think, but currently just implements
our bash version. Do our tests pass?

    ./test_check_file_exists

So yea, pretty much the same functionality as the bash version. What have we
gained? Well, in theory this check would work on systems, that maybe don't
have bash? Like Windows or BSD systems?

Also we are in a better position to add more logic and integrate with other
ruby libraries that interface with more interesting things. For example
in ruby you can get access to really good AWS libraries or http libraries
that might be cumbersome to replicate in bash.

### Expanding the check with negation

Let's expand this check in ruby to include the option to negate the check,
that is return "ok" the file isn't there, and critical when it is there.

Let's write our tests first:

```bash
touch test_file
./check_file_exists --inverse test_file
assert $? 2

rm -f test_file
./check_file_exists --inverse test_file
assert $? 0
```

I can't think of a much better term than just "inverse", as we are checking
the inverse of what we normally would be checking.

    ./test_check_file_exists


    Invalid check argument(s): invalid option: --inverse, ["/opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/mixlib-cli-1.5.0/lib/mixlib/cli.rb:191:in `parse_options'", "/opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/sensu-plugin-1.2.0/lib/sensu-plugin/cli.rb:13:in `initialize'", "/opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/sensu-plugin-1.2.0/lib/sensu-plugin/cli.rb:55:in `new'", "/opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/sensu-plugin-1.2.0/lib/sensu-plugin/cli.rb:55:in `block in <class:CLI>'"]

Our test fail of course because such an option doesn't exist. Let's add it.

To add this option, let's read up on the docs! The Sensu-plugin cli construct
uses the `milib-cli` gem to do command line parsing.

This adds a very easy to use dsl for adding command line options:

    https://github.com/chef/mixlib-cli

```ruby
option :inverse,
  :long => "--inverse",
  :description => "Return OK if the file doesn't exist, Critical if it exists",
  :boolean => true
```

You can call this magic, or you can just call it abstraction, but this
construct takes most of the gotchas out of command line parameter
parsing.

Now we can use this option in our code to invert our logic:

```ruby
    if File.exists?(filename)
      if not config[:inverse]
        ok "File '#{filename}' exists!"
      else
        critical "File '#{filename}'exists!"
      end
    else
      if not config[:inverse]
        critical "File '#{filename}' doesn't exist!"
      else
        ok "File '#{filename}' doesn't exist!"
      end
    end
```

There is almost certainly a better way to do this, but let's see if this works.
Notice how the command line parameters show up in this config dictionary for
use.

With this new flag we automatically get some command line help options now:

```
$ ./check_file_exists --help
Usage: ./check_file_exists (options)
        --inverse                    Return OK if the file doesn't exist, Critical if it exists
```

Pretty cool. And do our tests pass now?

    ./test_check_file_exists

They all pass, so now we have expanded our check to include the inverse logic
in case you need to be sure a file doesn't exist.

## Conclusion

In conclusion, writing Sensu checks is easy. You can use any language, even
just plain bash, but you also have Ruby and some sophisticated constructs
to reach for you want to.

But don't forget to not-reinvent the wheel. Not only are there plenty
of existing community Sensu plugins available for you to re-use, but
there are also tons of other monitoring plugins that written for other
tools that are also compatible, thanks to the Nagios-compliant
return-code api.

So go forth and write Sensu checks like a pro!

### Further Reading:

* [Sensu-plugin documentation](https://github.com/sensu-plugins/sensu-plugin)
