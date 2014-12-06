# Tutorial 2: gem dependencies

In [tutorial 1](TUTORIAL-1.md), we've packaged a hello world app and automated the process using Rake. In this tutorial, we'll continue to build on tutorial 1's sample app, by adding gem dependencies.

Your app can depend on any gem you wish, subject to the [limitations described in README.md](README.md#limitations). You must include the gems in your packages, and your wrapper script must pass the right parameters to the Ruby interpreter in order for your gems to be found. In this tutorial, we'll teach you how to manage gems using Bundler.

You can find the end result of this tutorial at https://github.com/phusion/traveling-ruby-gems-demo.

## Preparation

Suppose that we want our hello world app from tutorial 1 to print the message in red. We'll want to use [the paint gem](https://github.com/janlelis/paint) for that. Let's start by creating a Gemfile...

    source 'https://rubygems.org'
    gem 'paint'

...and by modifying hello.rb as follows:

    #!/usr/bin/env ruby
    require 'paint'
    puts Paint["hello world", :red]

You must install your gem bundle into some local directory, because during the packaging phase we'll want to copy all the files into the package directories. **You must run Bundler with Ruby 2.1** because the Traveling Ruby binaries are Ruby 2.1, and because Bundler installs into a directory that contains the Ruby version number. If you run Bundler using any other Ruby version, things will fail in a later step.

    $ ruby -v
    ruby 2.1.x [...]
    $ bundle install --path packaging/vendor

Then, using the Rakefile from tutorial 1, create package directories without creating tar.gz files:

    $ rake package DIR_ONLY=1

## Copying over gems

Copy over your Bundler gem directory into the package directories:

    $ cp -pR packaging/vendor hello-1.0.0-linux-x86/
    $ cp -pR packaging/vendor hello-1.0.0-linux-x86_64/
    $ cp -pR packaging/vendor hello-1.0.0-osx/

Copy over your Gemfile and Gemfile.lock into each gem directory inside the packages:

    $ cp Gemfile Gemfile.lock hello-1.0.0-linux-x86/vendor/
    $ cp Gemfile Gemfile.lock hello-1.0.0-linux-x86_64/vendor/
    $ cp Gemfile Gemfile.lock hello-1.0.0-osx/vendor/

## Bundler config file

Create a Bundler config file in each of the gem directories inside the packages. This Bundler config file tells Bundler that gems are to be found in the same directory that the Gemfile resides in.

Create `packaging/bundler-config` whih contains:

    BUNDLE_PATH: .
    BUNDLE_DISABLE_SHARED_GEMS: '1'

Then copy the file into `.bundle` directories inside the gem directories inside the packages;

    $ mkdir hello-1.0.0-linux-x86/vendor/.bundle
    $ mkdir hello-1.0.0-linux-x86_64/vendor/.bundle
    $ mkdir hello-1.0.0-osx/vendor/.bundle

    $ cp packaging/bundler-config hello-1.0.0-linux-x86/vendor/.bundle/config
    $ cp packaging/bundler-config hello-1.0.0-linux-x86_64/vendor/.bundle/config
    $ cp packaging/bundler-config hello-1.0.0-osx/vendor/.bundle/config

## Wrapper script

Modify the wrapper script `packaging/wrapper.sh`, which we originally created in [tutorial 1](TUTORIAL-1.md). It should be modified to perform two more things:

 1. It tells Bundler where your Gemfile is (and thus where the gems are).
 2. It executes your app with Bundler activated.

Here's how it looks like:

    #!/bin/bash
    set -e

    # Figure out where this script is located.
    SELFDIR="`dirname \"$0\"`"
    SELFDIR="`cd \"$SELFDIR\" && pwd`"

    # Tell Bundler where the Gemfile and gems are.
    export BUNDLE_GEMFILE="$SELFDIR/vendor/Gemfile"
    unset BUNDLE_IGNORE_CONFIG

    # Run the actual app using the bundled Ruby interpreter, with Bundler activated.
    exec "$SELFDIR/runtime/bin/ruby" -rbundler/setup "$SELFDIR/app/hello.rb"

Copy over this wrapper script to each of your package directories and finalize the packages:

    $ cp packaging/wrapper.sh hello-1.0.0-linux-x86/hello
    $ cp packaging/wrapper.sh hello-1.0.0-linux-x86_64/hello
    $ cp packaging/wrapper.sh hello-1.0.0-osx/hello

    $ tar -czf hello-1.0.0-linux-x86.tar.gz hello-1.0.0-linux-x86
    $ tar -czf hello-1.0.0-linux-x86_64.tar.gz hello-1.0.0-linux-x86_64
    $ tar -czf hello-1.0.0-osx.tar.gz hello-1.0.0-osx
    $ rm -rf hello-1.0.0-linux-x86
    $ rm -rf hello-1.0.0-linux-x86_64
    $ rm -rf hello-1.0.0-osx

## Automating the process using Rake

## Conclusion

You can download the end result of this tutorial at https://github.com/phusion/traveling-ruby-gems-demo.
