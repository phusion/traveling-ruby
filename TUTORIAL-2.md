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

We update the Rakefile so that all of the above steps are automated by running `rake package`. The various `package` tasks have been updated to run `package:bundle_install` which installs the gem bundle, and the `create_package` function has been updated to package the Gemfile and Bundler config file.

    PACKAGE_NAME = "hello"
    VERSION = "1.0.0"
    TRAVELING_RUBY_VERSION = "20141206-2.1.5"

    desc "Package your app"
    task :package => ['package:linux:x86', 'package:linux:x86_64', 'package:osx']

    namespace :package do
      namespace :linux do
        desc "Package your app for Linux x86"
        task :x86 => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz"] do
          create_package("linux-x86")
        end

        desc "Package your app for Linux x86_64"
        task :x86_64 => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz"] do
          create_package("linux-x86_64")
        end
      end

      desc "Package your app for OS X"
      task :osx => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz"] do
        create_package("osx")
      end

      desc "Install gems to local directory"
      task :bundle_install do
        if RUBY_VERSION !~ /^2\.1\./
          abort "You can only 'bundle install' using Ruby 2.1, because that's what Traveling Ruby uses."
        end
        sh "env BUNDLE_IGNORE_CONFIG=1 bundle install --path packaging/vendor"
      end
    end

    file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz" do
      download_runtime("linux-x86")
    end

    file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz" do
      download_runtime("linux-x86_64")
    end

    file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz" do
      download_runtime("osx")
    end

    def create_package(target)
      package_dir = "#{PACKAGE_NAME}-#{VERSION}-#{target}"
      sh "rm -rf #{package_dir}"
      sh "mkdir #{package_dir}"
      sh "mkdir #{package_dir}/app"
      sh "cp hello.rb #{package_dir}/app/"
      sh "mkdir #{package_dir}/runtime"
      sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz -C #{package_dir}/runtime"
      sh "cp packaging/wrapper.sh #{package_dir}/hello"
      sh "cp -pR packaging/vendor #{package_dir}/"
      sh "cp Gemfile Gemfile.lock #{package_dir}/vendor/"
      sh "mkdir #{package_dir}/vendor/.bundle"
      sh "cp packaging/bundler-config #{package_dir}/vendor/.bundle/config"
      if !ENV['DIR_ONLY']
        sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
        sh "rm -rf #{package_dir}"
      end
    end

    def download_runtime(target)
      sh "cd packaging && curl -L -O --fail " +
        "http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz"
    end

## Conclusion

You can download the end result of this tutorial at https://github.com/phusion/traveling-ruby-gems-demo.
