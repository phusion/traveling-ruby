# Tutorial 1: hello world

This tutorial teaches you, in 5 minutes, how to use Traveling Ruby to create self-contained packages of a hello world app. This app has no gem dependencies; dependency management is covered in [tutorial 2](TUTORIAL-2.md). We will be creating three packages, namely for Linux x86, Linux x86_64 and macOS.

This tutorial **does not cover Windows**. This tutorial [will not work on Windows](README.md#caveats); nor will this tutorial generate packages for Windows. The creation of packages for Windows is covered in [tutorial 4](TUTORIAL-4.md).

The process is as follows. First, you create several package directories (one for each target platform) and copy your app into the directory. Then you extract Traveling Ruby binaries into each directory, appropriate for that platform. Then you write a wrapper script so that users can conveniently start your app. Finally, you package everything up in tar.gz files, and automate the process.

You can find the end result of this tutorial at https://github.com/phusion/traveling-ruby-hello-demo.

The final hello world package weights 6 MB compressed.

## Preparation

Let's begin by creating a hello world app:

```Bash
mkdir hello_app
cd hello_app
echo '#!/usr/bin/env ruby' > hello.rb
echo 'puts "hello world"' >> hello.rb
ruby hello.rb
# => hello world
```

## Creating package directories

The next step is to prepare packages for all the target platforms, by creating a directory each platform, and by copying your app into each directory.

```Bash
mkdir -p hello-1.0.0-linux-x86/lib/app
cp hello.rb hello-1.0.0-linux-x86/lib/app/

mkdir -p hello-1.0.0-linux-x86_64/lib/app
cp hello.rb hello-1.0.0-linux-x86_64/lib/app/

mkdir -p hello-1.0.0-osx/lib/app/
cp hello.rb hello-1.0.0-osx/lib/app/
```

Next, create a `packaging` directory and download Traveling Ruby binaries for each platform into that directory. Then extract these binaries into each packaging directory. You can find a list of binaries at [the Traveling Ruby Amazon S3 bucket](https://traveling-ruby.s3-us-west-2.amazonaws.com/list.html). For faster download times, use the CloudFront domain "https://d6r77u77i8pq3.cloudfront.net". In this tutorial we're extracting version 20141215-2.1.5.

```Bash
mkdir packaging
cd packaging
curl -L -O --fail https://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-20141215-2.1.5-linux-x86.tar.gz
curl -L -O --fail https://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-20141215-2.1.5-linux-x86_64.tar.gz
curl -L -O --fail https://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-20141215-2.1.5-osx.tar.gz
cd ..

mkdir hello-1.0.0-linux-x86/lib/ruby && tar -xzf packaging/traveling-ruby-20141215-2.1.5-linux-x86.tar.gz -C hello-1.0.0-linux-x86/lib/ruby
mkdir hello-1.0.0-linux-x86_64/lib/ruby && tar -xzf packaging/traveling-ruby-20141215-2.1.5-linux-x86_64.tar.gz -C hello-1.0.0-linux-x86_64/lib/ruby
mkdir hello-1.0.0-osx/lib/ruby && tar -xzf packaging/traveling-ruby-20141215-2.1.5-osx.tar.gz -C hello-1.0.0-osx/lib/ruby
```

Now, each package directory will have Ruby binaries included. It looks like this:
Your directory structure will now look like this:

    hello_app/
     |
     +-- hello.rb
     |
     +-- hello-1.0.0-linux-x86/
     |   |
     |   +-- lib/
     |       +-- app/
     |       |   |
     |       |   +-- hello.rb
     |       |
     |       +-- ruby/
     |           |
     |           +-- bin/
     |           |   |
     |           |   +-- ruby
     |           |   +-- ...
     |           +-- ...
     |
     +-- hello-1.0.0-linux-x86_64/
     |   |
     |  ...
     |
     +-- hello-1.0.0-osx/
         |
        ...

### Quick sanity testing

Let's do a basic sanity test by running your app with a bundled Ruby interpreter. Suppose that you are developing on macOS. Run this:

```Bash
cd hello-1.0.0-osx
./lib/ruby/bin/ruby lib/app/hello.rb
# => hello world
cd ..
```

## Creating a wrapper script

Now that you've verified that the bundled Ruby interpreter works, you'll want create a *wrapper script*. After all, you don't want your users to run `/path-to-your-app/lib/ruby/bin/ruby /path-to-your-app/lib/app/hello.rb`. You want them to run `/path-to-your-app/hello`.

Here's what a wrapper script could look like:

```Bash
#!/bin/bash
set -e

# Figure out where this script is located.
SELFDIR="`dirname \"$0\"`"
SELFDIR="`cd \"$SELFDIR\" && pwd`"

# Run the actual app using the bundled Ruby interpreter.
exec "$SELFDIR/lib/ruby/bin/ruby" "$SELFDIR/lib/app/hello.rb" "$@"
```

Save this file as `packaging/wrapper.sh` in your project's root directory. Then you can copy it to each of your package directories and name it `hello`:

```Bash
editor packaging/wrapper.sh
...edit the file as per above...
chmod +x packaging/wrapper.sh
cp packaging/wrapper.sh hello-1.0.0-linux-x86/hello
cp packaging/wrapper.sh hello-1.0.0-linux-x86_64/hello
cp packaging/wrapper.sh hello-1.0.0-osx/hello
```

## Finalizing packages

Your package directories are now ready. You can finalize the packages by packaging up all these directories using tar:

```Bash
tar -czf hello-1.0.0-linux-x86.tar.gz hello-1.0.0-linux-x86
tar -czf hello-1.0.0-linux-x86_64.tar.gz hello-1.0.0-linux-x86_64
tar -czf hello-1.0.0-osx.tar.gz hello-1.0.0-osx
rm -rf hello-1.0.0-linux-x86
rm -rf hello-1.0.0-linux-x86_64
rm -rf hello-1.0.0-osx
```

Congratulations, you have created packages using Traveling Ruby!

An x86 Linux user could now use your app like this:

 1. The user downloads `hello-1.0.0-linux-x86.tar.gz`.
 2. The user extracts this file.
 3. The user runs your app:

```Bash
/path-to/hello-1.0.0-linux-x86/hello
# => hello world
```

## Automating the process using Rake

Going through all of the above steps on every release is a hassle, so you should automate the packaging process, for example by using Rake. Here's how the Rakefile could look like:

```Ruby
PACKAGE_NAME = "hello"
VERSION = "1.0.0"
TRAVELING_RUBY_VERSION = "20150210-2.1.5"

desc "Package your app"
task :package => ['package:linux:x86', 'package:linux:x86_64', 'package:osx']

namespace :package do
  namespace :linux do
    desc "Package your app for Linux x86"
    task :x86 => "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz" do
      create_package("linux-x86")
    end

    desc "Package your app for Linux x86_64"
    task :x86_64 => "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz" do
      create_package("linux-x86_64")
    end
  end

  desc "Package your app for macOS"
  task :osx => "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz" do
    create_package("osx")
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
  sh "mkdir -p #{package_dir}/lib/app"
  sh "cp hello.rb #{package_dir}/lib/app/"
  sh "mkdir #{package_dir}/lib/ruby"
  sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz -C #{package_dir}/lib/ruby"
  sh "cp packaging/wrapper.sh #{package_dir}/hello"
  if !ENV['DIR_ONLY']
    sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
    sh "rm -rf #{package_dir}"
  end
end

def download_runtime(target)
  sh "cd packaging && curl -L -O --fail " +
    "https://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz"
end
```

You can then create all 3 packages by running:

```Bash
rake package
```

You can also create a package for a specific platform by running one of:

```Bash
rake package:linux:x86
rake package:linux:x86_64
rake package:osx
```

You can also just create package directories, without creating the .tar.gz files, by passing DIR_ONLY=1:

```Bash
rake package DIR_ONLY=1
rake package:linux:x86 DIR_ONLY=1
rake package:linux:x86_64 DIR_ONLY=1
rake package:osx DIR_ONLY=1
```

## End users

You now have three files which you can distribute to end users.

 * hello-1.0.0-linux-x86.tar.gz
 * hello-1.0.0-linux-x86_64.tar.gz
 * hello-1.0.0-osx.tar.gz

Suppose the end user is on Linux x86_64. S/he uses your app by downloading `hello-1.0.0-linux-x86_64.tar.gz`, extracting it and running it:

```Bash
wget hello-1.0.0-linux-x86_64.tar.gz
...
tar xzf hello-1.0.0-linux-x86_64.tar.gz
cd hello-1.0.0-linux-x86_64
./hello
# => hello world
```

## Conclusion

You can download the end result of this tutorial at https://github.com/phusion/traveling-ruby-hello-demo.

Creating self-contained packages with Traveling Ruby is simple and straightforward. But most apps will have gem dependencies. [Read tutorial 2](TUTORIAL-2.md) to learn how to handle gem dependencies.
