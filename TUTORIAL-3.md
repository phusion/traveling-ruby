# Tutorial 3: native extensions

In [tutorial 2](TUTORIAL-2.md) we covered gem dependencies. But those were only gems without native extensions. In this third tutorial we'll cover the usage of native extensions.

Normally, native extensions need to be compiled. But the goal of Traveling Ruby is to enable packaging for multiple platforms, no matter which OS you are developing on, so we obviously can't ask you to compile native extensions yourself. Aside from the hassle of compiling, compiling native extensions that would work on every system is a challenge in itself.

So instead, the Traveling Ruby project supplies a number of precompiled native extensions that you can drop into your packages. Only specific versions are supplied, so your Gemfile must match the versions of the native extension gems that we supply.

**Windows notes**: native extenstions are not yet supported in Windows! See the [caveats](README.md#caveats).

## Preparation

Suppose that we want our hello world app from tutorial 2 to insert a row into an SQLite database file. We'll want to use the sqlite3 gem for that.

Traveling Ruby provides a specific version of the sqlite3 gem. See [the Traveling Ruby Amazon S3 bucket](http://traveling-ruby.s3-us-west-2.amazonaws.com/list.html). For version 20141215-2.1.5, version 1.3.9 is supplied. So we add the following to our Gemfile:

    gem 'sqlite3', '1.3.9'

Let's also modify hello.rb to do what we want:

    #!/usr/bin/env ruby
    require 'faker'
    require 'sqlite3'

    db = SQLite3::Database.new("hello.sqlite3")
    db.execute("create table if not exists foo (name varchar(255))")
    db.execute("insert into foo values ('hello world')")
    db.close
    puts "Hello #{Faker::Name.name}, database file modified."

Then install your gem bundle:

    $ bundle install

Verify that the modified program works:

    $ bundle exec ruby hello.rb
    Hello Freida Walker, database file modified.
    $ sqlite3 hello.sqlite3
    sqlite> select * from foo;
    name
    -----------
    hello world

## Preparing the gem bundle, without native extensions

Recall that the idea is that we create a package for every platform, and that we drop platform-specific precompiled native extensions in every package. But there's a little problem that we need to solve first. When you run `rake package`, it runs Bundler to create a local gem bundle for inclusion in packages. However, Bundler compiles native extensions for the platform that you're currently running on, but we don't want that to happen. So in this step, we must clean those things up.

Using the Rakefile from tutorial 2, create the gem bundle which is to be included in packages:

    $ rake package:bundle_install

Run these to remove any native extensions and compilation products from that bundle:

    $ rm -rf packaging/vendor/ruby/*/extensions
    $ find packaging/vendor/ruby/*/gems -name '*.so' | xargs rm -f
    $ find packaging/vendor/ruby/*/gems -name '*.bundle' | xargs rm -f
    $ find packaging/vendor/ruby/*/gems -name '*.o' | xargs rm -f

## Dropping native extensions

Now you are ready to drop platform-specific native extensions inside the packages. First, create the package directories:

    $ rake package DIR_ONLY=1

Next you must download the necessary native extensions, and extract them into `<PACKAGE DIR>/lib/vendor`. You can find native extensions at [the Traveling Ruby Amazon S3 bucket](http://traveling-ruby.s3-us-west-2.amazonaws.com/list.html). Suppose that you're using Traveling Ruby version 20141215-2.1.5, which supplies sqlite3 version 1.3.9. Download and extract the precompiled binaries as follows. Remember that we're using CloudFront domain "http://d6r77u77i8pq3.cloudfront.net" to speed up downloads.

    $ cd hello-1.0.0-linux-x86/lib/vendor/ruby
    $ curl -L -O --fail http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-gems-20141215-2.1.5-linux-x86/sqlite3-1.3.9.tar.gz
    $ tar xzf sqlite3-1.3.9.tar.gz
    $ rm sqlite3-1.3.9.tar.gz
    $ cd ../../../..

    $ cd hello-1.0.0-linux-x86_64/lib/vendor/ruby
    $ curl -L -O --fail http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-gems-20141215-2.1.5-linux-x86_64/sqlite3-1.3.9.tar.gz
    $ tar xzf sqlite3-1.3.9.tar.gz
    $ rm sqlite3-1.3.9.tar.gz
    $ cd ../../../..

    $ cd hello-1.0.0-osx/lib/vendor/ruby
    $ curl -L -O --fail http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-gems-20141215-2.1.5-osx/sqlite3-1.3.9.tar.gz
    $ tar xzf sqlite3-1.3.9.tar.gz
    $ rm sqlite3-1.3.9.tar.gz
    $ cd ../../../..

## Finishing up

Package the directories and finalize the packages:

    $ tar -czf hello-1.0.0-linux-x86.tar.gz hello-1.0.0-linux-x86
    $ tar -czf hello-1.0.0-linux-x86_64.tar.gz hello-1.0.0-linux-x86_64
    $ tar -czf hello-1.0.0-osx.tar.gz hello-1.0.0-osx
    $ rm -rf hello-1.0.0-linux-x86
    $ rm -rf hello-1.0.0-linux-x86_64
    $ rm -rf hello-1.0.0-osx

Now you can test whether it works. Suppose that you're developing on OS X. Extract the OS X package and test it:

    $ tar xzf hello-1.0.0-osx.tar.gz
    $ cd hello-1.0.0-osx
    $ ./hello
    Database file modified. (in red)
    $ sqlite3 hello.sqlite3
    sqlite> select * from foo;
    name
    -----------
    hello world

## Automating the process using Rake

We update the Rakefile so that all of the above steps are automated by running `rake package`. The `package:bundle_install` task has been updated to remove any locally compiled native extensions. The various packaging tasks have been updated to extract platform-specific native extension binaries.

	# For Bundler.with_clean_env
	require 'bundler/setup'

	PACKAGE_NAME = "hello"
	VERSION = "1.0.0"
	TRAVELING_RUBY_VERSION = "20150210-2.1.5"
	SQLITE3_VERSION = "1.3.9"  # Must match Gemfile

	desc "Package your app"
	task :package => ['package:linux:x86', 'package:linux:x86_64', 'package:osx']

	namespace :package do
	  namespace :linux do
	    desc "Package your app for Linux x86"
	    task :x86 => [:bundle_install,
	      "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz",
	      "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86-sqlite3-#{SQLITE3_VERSION}.tar.gz"
	    ] do
	      create_package("linux-x86")
	    end

	    desc "Package your app for Linux x86_64"
	    task :x86_64 => [:bundle_install,
	      "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz",
	      "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64-sqlite3-#{SQLITE3_VERSION}.tar.gz"
	    ] do
	      create_package("linux-x86_64")
	    end
	  end

	  desc "Package your app for OS X"
	  task :osx => [:bundle_install,
	    "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz",
	    "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx-sqlite3-#{SQLITE3_VERSION}.tar.gz"
	  ] do
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
	    sh "rm -rf packaging/vendor/ruby/*/extensions"
	    sh "find packaging/vendor/ruby/*/gems -name '*.so' | xargs rm -f"
	    sh "find packaging/vendor/ruby/*/gems -name '*.bundle' | xargs rm -f"
	    sh "find packaging/vendor/ruby/*/gems -name '*.o' | xargs rm -f"
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

	file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86-sqlite3-#{SQLITE3_VERSION}.tar.gz" do
	  download_native_extension("linux-x86", "sqlite3-#{SQLITE3_VERSION}")
	end

	file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64-sqlite3-#{SQLITE3_VERSION}.tar.gz" do
	  download_native_extension("linux-x86_64", "sqlite3-#{SQLITE3_VERSION}")
	end

	file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx-sqlite3-#{SQLITE3_VERSION}.tar.gz" do
	  download_native_extension("osx", "sqlite3-#{SQLITE3_VERSION}")
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
	  sh "tar -xzf packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}-sqlite3-#{SQLITE3_VERSION}.tar.gz " +
	    "-C #{package_dir}/lib/vendor/ruby"
	  if !ENV['DIR_ONLY']
	    sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
	    sh "rm -rf #{package_dir}"
	  end
	end

	def download_runtime(target)
	  sh "cd packaging && curl -L -O --fail " +
	    "http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz"
	end

	def download_native_extension(target, gem_name_and_version)
	  sh "curl -L --fail -o packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}-#{gem_name_and_version}.tar.gz " +
	    "http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-gems-#{TRAVELING_RUBY_VERSION}-#{target}/#{gem_name_and_version}.tar.gz"
	end

## Conclusion

In this tutorial you've learned how to deal with native extensions. You can download the end result of this tutorial at https://github.com/phusion/traveling-ruby-native-extensions-demo.

In all the tutorials so far, we've not covered Windows. Proceed with [tutorial 4](TUTORIAL-4.md) to learn about creating Windows packages.
