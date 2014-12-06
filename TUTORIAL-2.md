# Tutorial 2: gem dependencies

Your app can depend on any gem you wish, subject to the [limitations described in README.md](README.md#limitations). You must include the gems in your packages, and your wrapper script must pass the right parameters to the Ruby interpreter in order for your gems to be found. In this tutorial, we'll teach you how to manage gems using Bundler.

## Preparation

Suppose that you want to use the [Methadone](https://github.com/davetron5000/methadone) gem. Start by creating a Gemfile:

    source 'https://rubygems.org'
    gem 'methadone'

You must install your gem bundle into some local directory, because during the packaging phase we'll want to copy all the files into the package directories. **You must run Bundler with Ruby 2.1** because the Traveling Ruby binaries are Ruby 2.1, and because Bundler installs into a directory that contains the Ruby version number. If you run Bundler using any other Ruby version, things will fail in a later step.

    $ ruby -v
    ruby 2.1.x [...]
    $ bundle install --path vendor

## Creating package directories

Create your package directories and extract Traveling Ruby binaries into them, as was described in [tutorial 1](TUTORIAL-1.md).

    $ mkdir hello-1.0.0-linux-x86
    $ mkdir hello-1.0.0-linux-x86/app
    $ cp hello.rb hello-1.0.0-linux-x86/app/
    $ traveling-ruby extract linux-x86 hello-1.0.0-linux-x86/runtime

    # Repeat the above for:
    # linux-x86_64
    # osx

## Copying over gems

Copy over your Bundler gem directory into the package directories:

    $ cp -pR vendor hello-1.0.0-linux-x86/
    $ cp -pR vendor hello-1.0.0-linux-x86_64/
    $ cp -pR vendor hello-1.0.0-osx/

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

Create a wrapper script `packaging/wrapper.sh`. This is like the wrapper script in [tutorial 1](TUTORIAL-1.md), but it has been modified to perform two more things:

 1. It tells Bundler where your Gemfile is (and thus where the gems are).
 2. It executes your app with Bundler activated.

Here's how it looks like:

    #!/bin/bash
    set -e

    # Figure out where this script is located.
    SELFDIR="`dirname \"$0\"`"
    SELFDIR="`cd \"$SELFDIR\" && pwd`"

    # Tell Bundler where the Gemfile and gems are.
    export BUNDLE_GEMFILE="$SELFDIR/vendor"

    # Run the actual app using the bundled Ruby interpreter, with Bundler activated.
    exec "$SELFDIR/runtime/bin/ruby" -rbundler/setup "$SELFDIR/app/hello.rb"

Copy over this wrapper script to each of your package directories and finalize the packages:

    $ chmod +x packaging/wrapper.sh
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

