# Tutorial 2: gem dependencies

Your app can depend on any gem you wish, subject to the [limitations described in README.md](README.md#limitations). You must include the gems in your packages, and your wrapper script must pass the right parameters to the Ruby interpreter in order for your gems to be found. It is recommended that you manage gems using Bundler.

For example, suppose that you want to use the [Methadone](https://github.com/davetron5000/methadone) gem. Start by creating a Gemfile:

    source 'https://rubygems.org'
    gem 'methadone'

Next, install your gem bundle into some local directory, because during the packaging phase we'll want to copy all the files into the package directories. **You must run Bundler with Ruby 2.1** because the Traveling Ruby binaries are Ruby 2.1, and because Bundler installs into a directory that contains the Ruby version number.

   $ ruby -v
   ruby 2.1 ...
   $ bundle install --path vendor

Then create your package directories and extract Traveling Ruby binaries into them, as was described in "Getting started".

    $ mkdir hello-1.0.0-linux-x86
    $ mkdir hello-1.0.0-linux-x86/app
    $ cp hello.rb hello-1.0.0-linux-x86/app/
    $ traveling-ruby extract linux-x86 hello-1.0.0-linux-x86/runtime

    # Repeat the above for:
    # linux-x86_64
    # osx

Copy over your Bundler gem directory into the packages:

    $ cp -pR vendor hello-1.0.0-linux-x86/
    $ cp -pR vendor hello-1.0.0-linux-x86_64/
    $ cp -pR vendor hello-1.0.0-osx/

Copy over your Gemfile and Gemfile.lock into each gem directory inside the packages:

    $ cp Gemfile Gemfile.lock hello-1.0.0-linux-x86/vendor/
    $ cp Gemfile Gemfile.lock hello-1.0.0-linux-x86_64/vendor/
    $ cp Gemfile Gemfile.lock hello-1.0.0-osx/vendor/

Create a Bundler config file in each of the gem directories inside the packages. This Bundler config file tells Bundler that gems are to be found in the same directory that the Gemfile resides in.

    $ editor bundler-config
    BUNDLE_PATH: .
    BUNDLE_DISABLE_SHARED_GEMS: '1'

    $ mkdir hello-1.0.0-linux-x86/vendor/.bundle
    $ mkdir hello-1.0.0-linux-x86_64/vendor/.bundle
    $ mkdir hello-1.0.0-osx/vendor/.bundle

    $ cp bundler-config hello-1.0.0-linux-x86/vendor/.bundle/config
    $ cp bundler-config hello-1.0.0-linux-x86_64/vendor/.bundle/config
    $ cp bundler-config hello-1.0.0-osx/vendor/.bundle/config

Create a wrapper script `wrapper.sh` that tells Bundler where your Gemfile is (and where the gems are), and executes your app using Bundler:

    #!/bin/bash
    set -e

    # Figure out where this script is located.
    SELFDIR="`dirname \"$0\"`"
    SELFDIR="`cd \"$SELFDIR\" && pwd`"

    # Tell Bundler where the Gemfile and gems are.
    export BUNDLE_GEMFILE="$SELFDIR/vendor"

    # Run the actual app using the bundled Ruby interpreter, with Bundler activated.
    exec "$SELFDIR/runtime/bin/ruby" -rbundler/setup "$SELFDIR/app/hello.rb"

Copy over this new wrapper script to each of your package directories and finalize the packages:

    $ chmod +x wrapper.sh
    $ cp wrapper.sh hello-1.0.0-linux-x86/hello
    $ cp wrapper.sh hello-1.0.0-linux-x86_64/hello
    $ cp wrapper.sh hello-1.0.0-osx/hello

    $ tar -czf hello-1.0.0-linux-x86.tar.gz hello-1.0.0-linux-x86
    $ tar -czf hello-1.0.0-linux-x86_64.tar.gz hello-1.0.0-linux-x86_64
    $ tar -czf hello-1.0.0-osx.tar.gz hello-1.0.0-osx
    $ rm -rf hello-1.0.0-linux-x86
    $ rm -rf hello-1.0.0-linux-x86_64
    $ rm -rf hello-1.0.0-osx
