# Tutorial 2: gem dependencies

In [tutorial 1](TUTORIAL-1.md), we've packaged a hello world app and automated the process using Rake. In this tutorial, we'll continue to build on tutorial 1's sample app, by adding gem dependencies.

Your app can depend on any gem you wish, subject to the [limitations described in README.md](README.md#limitations). You must include the gems in your packages, and your wrapper script must pass the right parameters to the Ruby interpreter in order for your gems to be found. In this tutorial, we'll teach you how to manage gems using Bundler.

Gems with native extensions are not covered in this second tutorial. They're covered in [tutorial 3](TUTORIAL-3.md).

You can find the end result of this tutorial at https://github.com/phusion/traveling-ruby-gems-demo.

## Preparation

Suppose that we want our hello world app from tutorial 1 to print the message in red. We'll want to use [the paint gem](https://github.com/janlelis/paint) for that. Let's start by creating a Gemfile...

```Ruby
source 'https://rubygems.org'

gem 'paint'

group :development do
  gem 'rake'
end
```

...and by modifying hello.rb as follows:

```Ruby
#!/usr/bin/env ruby
require 'paint'
puts Paint["hello world", :red]
```

Then install your gem bundle:

```Bash
bundle install
```

Verify that your hello world works:

```Bash
bundle exec ruby hello.rb
# => hello world (in red)
```

Then, using the Rakefile from tutorial 1, create package directories without creating tar.gz files:

```Bash
rake package DIR_ONLY=1
```

## Installing gems for packaging

In the previous step, we used Bundler to install gems so that you can run your app during development. But you *also* need to run Bundler a second time, to install the gems that you want to include in your package. During the packaging phase, the gems installed by this second Bundler invocation will be copied into the packages.

But first, be aware that you must run this Bundler instance with the same Ruby version that you intend to package with, because Bundler installs into a directory that contains the Ruby version number. Traveling Ruby currently supports Ruby 2.1.5 and 2.2.0, but this tutorial utilizes Ruby 2.1.5. **So in this tutorial you must run Bundler with Ruby 2.1.** If you run Bundler using any other Ruby version, things will fail in a later step.

So first verify your Ruby version:

```Bash
ruby -v
# => ruby 2.1.x [...]
```

Next, install the gem bundle for packaging. We do this by copying the Gemfile to a temporary directory and running Bundler there, because passing `--path` and `--without` to Bundler will change its configuration file. We don't want to persist such changes in our development Bundler config.

```Bash
mkdir packaging/tmp
cp Gemfile Gemfile.lock packaging/tmp/
cd packaging/tmp
BUNDLE_IGNORE_CONFIG=1 bundle install --path ../vendor --without development
cd ../..
rm -rf packaging/tmp
```

Note that we passed `--without development` so that Rake isn't installed. In the final packages there is no need to include Rake.

Bundler also stores various cache files, which we also don't need to package, so we remove them:

```Bash
rm -f packaging/vendor/*/*/cache/*
```

## Copying gems into package directories

Copy the Bundler gem bundle that you installed in the last step, into the package directories:

```Bash
cp -pR packaging/vendor hello-1.0.0-linux-x86/lib/
cp -pR packaging/vendor hello-1.0.0-linux-x86_64/lib/
cp -pR packaging/vendor hello-1.0.0-osx/lib/
```

Copy over your Gemfile and Gemfile.lock into each gem directory inside the packages:

```Bash
cp Gemfile Gemfile.lock hello-1.0.0-linux-x86/lib/vendor/
cp Gemfile Gemfile.lock hello-1.0.0-linux-x86_64/lib/vendor/
cp Gemfile Gemfile.lock hello-1.0.0-osx/lib/vendor/
```

## Bundler config file

We must create a Bundler config file for each of the gem directories inside the packages. This Bundler config file tells Bundler that gems are to be found in the same directory that the Gemfile resides in, and that gems in the "development" group should not be loaded.

First, create `packaging/bundler-config` which contains:

```Bash
BUNDLE_PATH: .
BUNDLE_WITHOUT: development
BUNDLE_DISABLE_SHARED_GEMS: '1'
```

Then copy the file into `.bundle` directories inside the gem directories inside the packages;

```Bash
mkdir hello-1.0.0-linux-x86/lib/vendor/.bundle
mkdir hello-1.0.0-linux-x86_64/lib/vendor/.bundle
mkdir hello-1.0.0-osx/lib/vendor/.bundle

cp packaging/bundler-config hello-1.0.0-linux-x86/lib/vendor/.bundle/config
cp packaging/bundler-config hello-1.0.0-linux-x86_64/lib/vendor/.bundle/config
cp packaging/bundler-config hello-1.0.0-osx/lib/vendor/.bundle/config
```

## Wrapper script

Modify the wrapper script `packaging/wrapper.sh`, which we originally created in [tutorial 1](TUTORIAL-1.md). It should be modified to perform two more things:

 1. It tells Bundler where your Gemfile is (and thus where the gems are).
 2. It executes your app with Bundler activated.

Here's how it looks like:

```Bash
#!/bin/bash
set -e

# Figure out where this script is located.
SELFDIR="`dirname \"$0\"`"
SELFDIR="`cd \"$SELFDIR\" && pwd`"

# Tell Bundler where the Gemfile and gems are.
export BUNDLE_GEMFILE="$SELFDIR/lib/vendor/Gemfile"
unset BUNDLE_IGNORE_CONFIG

# Run the actual app using the bundled Ruby interpreter, with Bundler activated.
exec "$SELFDIR/lib/ruby/bin/ruby" -rbundler/setup "$SELFDIR/lib/app/hello.rb"
```

Copy over this wrapper script to each of your package directories and finalize the packages:

```Bash
cp packaging/wrapper.sh hello-1.0.0-linux-x86/hello
cp packaging/wrapper.sh hello-1.0.0-linux-x86_64/hello
cp packaging/wrapper.sh hello-1.0.0-osx/hello

tar -czf hello-1.0.0-linux-x86.tar.gz hello-1.0.0-linux-x86
tar -czf hello-1.0.0-linux-x86_64.tar.gz hello-1.0.0-linux-x86_64
tar -czf hello-1.0.0-osx.tar.gz hello-1.0.0-osx
rm -rf hello-1.0.0-linux-x86
rm -rf hello-1.0.0-linux-x86_64
rm -rf hello-1.0.0-osx
```

## Automating the process using Rake

We update the Rakefile so that all of the above steps are automated by running `rake package`. The various `package` tasks have been updated to run `package:bundle_install` which installs the gem bundle, and the `create_package` function has been updated to package the Gemfile and Bundler config file.

```Ruby
# For Bundler.with_clean_env
require 'bundler/setup'

PACKAGE_NAME = "hello"
VERSION = "1.0.0"
TRAVELING_RUBY_VERSION = "20141215-2.1.5"

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
    sh "rm -rf packaging/tmp"
    sh "mkdir packaging/tmp"
    sh "cp Gemfile Gemfile.lock packaging/tmp/"
    Bundler.with_clean_env do
      sh "cd packaging/tmp && env BUNDLE_IGNORE_CONFIG=1 bundle install --path ../vendor --without development"
    end
    sh "rm -rf packaging/tmp"
    sh "rm -f packaging/vendor/*/*/cache/*"
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
  sh "mkdir -p #{package_dir}/lib/app"
  sh "cp hello.rb #{package_dir}/lib/app/"
  sh "mkdir #{package_dir}/lib/ruby"
  sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz -C #{package_dir}/lib/ruby"
  sh "cp packaging/wrapper.sh #{package_dir}/hello"
  sh "cp -pR packaging/vendor #{package_dir}/lib/"
  sh "cp Gemfile Gemfile.lock #{package_dir}/lib/vendor/"
  sh "mkdir #{package_dir}/lib/vendor/.bundle"
  sh "cp packaging/bundler-config #{package_dir}/lib/vendor/.bundle/config"
  if !ENV['DIR_ONLY']
    sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
    sh "rm -rf #{package_dir}"
  end
end

def download_runtime(target)
  sh "cd packaging && curl -L -O --fail " +
    "http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz"
end
```

## Conclusion

In this tutorial you've learned how to work with gem dependencies. You can download the end result of this tutorial at https://github.com/phusion/traveling-ruby-gems-demo.

But this tutorial does not cover native extensions. To learn how to deal with native extensions, go to [tutorial 3](TUTORIAL-3.md).
