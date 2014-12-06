# Tutorial 1: hello world

This tutorial teaches you, in 5 minutes, how to use Traveling Ruby to create self-contained packages of a hello world app. This app has no gem dependencies; dependeny management is covered in tutorial 2. We will be creating three packages, namely for Linux x86, Linux x86_64 and OS X.

The process is as follows. First, you create several package directories (one for each target platform) and copy your app into the directory. Then you extract Traveling Ruby binaries into each directory, appropriate for that platform. Then you write a wrapper script so that users can conveniently start your app. Finally, you package everything up in tar.gz files, and automate the process.

You can find the end result of this tutorial at https://github.com/phusion/traveling-ruby-hello-demo.

## Preparation

Let's begin by creating a hello world app:

    $ mkdir hello_app
    $ cd hello_app
    $ echo '#!/usr/bin/env ruby' > hello.rb
    $ echo 'puts "hello world"' >> hello.rb
    $ ruby hello.rb
    hello world

You must also install the Traveling Ruby SDK, which will give you the `traveling-ruby` command.

    gem install traveling-ruby

## Creating package directories

The next step is to prepare packages for all the target platforms, by creating a directory each platform, and by copying your app into each directory.

    $ mkdir hello-1.0.0-linux-x86
    $ mkdir hello-1.0.0-linux-x86/app
    $ cp hello.rb hello-1.0.0-linux-x86/app/

    $ mkdir hello-1.0.0-linux-x86_64
    $ mkdir hello-1.0.0-linux-x86_64/app
    $ cp hello.rb hello-1.0.0-linux-x86_64/app/

    $ mkdir hello-1.0.0-osx
    $ mkdir hello-1.0.0-osx/app
    $ cp hello.rb hello-1.0.0-osx/app/

Next, use the `traveling-ruby extract <PLATFORM> <DIRECTORY>` command to download binaries for each platform, and to extract them into each directory.

    $ traveling-ruby extract linux-x86 hello-1.0.0-linux-x86/runtime
    $ traveling-ruby extract linux-x86_64 hello-1.0.0-linux-x86_64/runtime
    $ traveling-ruby extract osx hello-1.0.0-osx/runtime

Now, each package directory will have Ruby binaries included. It looks like this:
Your directory structure will now look like this:

    hello_app/
     |
     +-- hello.rb
     |
     +-- hello-1.0.0-linux-x86/
     |   |
     |   +-- app/
     |   |   |
     |   |   +-- hello.rb
     |   |
     |   +-- ruby/
     |       |
     |       +-- bin/
     |       |   |
     |       |   +-- ruby
     |       |   +-- ...
     |       +-- ...
     |
     +-- hello-1.0.0-linux-x86_64/
     |   |
     |  ...
     |
     +-- hello-1.0.0-osx/
         |
        ...

### Quick sanity testing

Let's do a basic sanity test by running your app with a bundled Ruby interpreter. Suppose that you are developing on OS X. Run this:

    $ cd hello-1.0.0-osx
    $ ./runtime/bin/ruby app/hello.rb
    hello world
    $ cd ..

## Creating a wrapper script

Now that you've verified that the bundled Ruby interpreter works, you'll want create a *wrapper script*. After all, you don't want your users to run `/path-to-your-app/runtime/bin/ruby /path-to-your-app/app/hello.rb`. You want them to run `/path-to-your-app/hello`.

Here's what a wrapper script could look like:

    #!/bin/bash
    set -e

    # Figure out where this script is located.
    SELFDIR="`dirname \"$0\"`"
    SELFDIR="`cd \"$SELFDIR\" && pwd`"

    # Run the actual app using the bundled Ruby interpreter.
    exec "$SELFDIR/runtime/bin/ruby" "$SELFDIR/app/hello.rb"

Save this file as `packaging/wrapper.sh` in your project's root directory. Then you can copy it to each of your package directories and name it `hello`:

    $ mkdir packaging
    $ editor packaging/wrapper.sh
    ...edit the file as per above...
    $ chmod +x packaging/wrapper.sh
    $ cp packaging/wrapper.sh hello-1.0.0-linux-x86/hello
    $ cp packaging/wrapper.sh hello-1.0.0-linux-x86_64/hello
    $ cp packaging/wrapper.sh hello-1.0.0-osx/hello

## Finalizing packages

Your package directories are now ready. You can finalize the packages by packaging up all these directories using tar:

    $ tar -czf hello-1.0.0-linux-x86.tar.gz hello-1.0.0-linux-x86
    $ tar -czf hello-1.0.0-linux-x86_64.tar.gz hello-1.0.0-linux-x86_64
    $ tar -czf hello-1.0.0-osx.tar.gz hello-1.0.0-osx
    $ rm -rf hello-1.0.0-linux-x86
    $ rm -rf hello-1.0.0-linux-x86_64
    $ rm -rf hello-1.0.0-osx

Congratulations, you have created packages using Traveling Ruby!

An x86 Linux user could now use your app like this:

 1. The user downloads `hello-1.0.0-linux-x86.tar.gz`.
 2. The user extracts this file.
 3. The user runs your app:

         $ /path-to/hello-1.0.0-linux-x86/hello
         hello world

## Automating the process using Rake

Going through all of the above steps on every release is a hassle, so you should automate the packaging process, for example by using Rake. Here's how the Rakefile could look like:

    PACKAGE_NAME = "hello"
    VERSION = "1.0.0"

    desc "Package your app"
    task :package => ['package:linux:x86', 'package:linux:x86_64', 'package:osx']

    namespace :package do
      namespace :linux do
        desc "Package your app for Linux x86"
        task :x86 do
          create_package("linux-x86")
        end

        desc "Package your app for Linux x86_64"
        task :x86_64 do
          create_package("linux-x86_64")
        end
      end

      desc "Package your app for OS X"
      task :osx do
        create_package("osx")
      end
    end

    def create_package(target)
      package_dir = "#{PACKAGE_NAME}-#{VERSION}-#{target}"
      sh "rm -rf #{package_dir}"
      sh "mkdir #{package_dir}"
      sh "mkdir #{package_dir}/app"
      sh "cp hello.rb #{package_dir}/app/"
      sh "traveling-ruby extract #{package_dir}/runtime"
      sh "cp packaging/wrapper.sh #{package_dir}/hello"
      sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
      sh "rm -rf #{package_dir}"
    end

You can then create all 3 packages by running:

    $ rake package

You can also create a package for a specific platform by running one of:

    $ rake package:linux:x86
    $ rake package:linux:x86_64
    $ rake package:osx

## End users

You now have three files which you can distribute to end users.

 * hello-1.0.0-linux-x86.tar.gz
 * hello-1.0.0-linux-x86_64.tar.gz
 * hello-1.0.0-osx.tar.gz

Suppose the end user is on Linux x86_64. S/he uses your app by downloading `hello-1.0.0-linux-x86_64.tar.gz`, extracting it and running it:

    user$ wget hello-1.0.0-linux-x86_64.tar.gz
    ...
    user$ tar xzf hello-1.0.0-linux-x86_64.tar.gz
    user$ cd hello-1.0.0-linux-x86_64
    user$ ./hello
    hello world

## Conclusion

Creating self-contained packages with Traveling Ruby is simple and straightforward. But most apps will have gem dependencies. [Read tutorial 2](TUTORIAL-2.md) to learn how to handle gem dependencies.
