# Traveling Ruby: self-contained, portable Ruby binaries

![](https://openclipart.org/image/300px/svg_to_png/181225/Travel_backpacks.png)

Traveling Ruby is a project which supplies self-contained, "portable" Ruby binaries: Ruby binaries that can run on any Linux distribution and any OS X machine. This allows Ruby app developers to bundle these binaries with their Ruby app, so that they can distribute a single package to end users, without needing end users to first install Ruby or gems.

[![](https://raw.githubusercontent.com/phusion/traveling-ruby/master/doc/video.png)](https://vimeo.com/phusionnl/review/113827942/ceca7e70da)

_Introduction in 2 minutes_

## Motivation

Ruby is one of our favorite programming languages. Most people use it for web development, but Ruby is so much more. We at Phusion have been using Ruby for years for writing sysadmin automation scripts, developer command line tools and more. [Heroku's Toolbelt](https://toolbelt.heroku.com/) and [Chef](https://www.chef.io/) have also demonstrated that Ruby is an excellent language for these sorts of things.

However, distributing such Ruby apps to inexperienced end users or non-Ruby-programmer end users is problematic. If users have to install Ruby first, or if they have to use RubyGems, [they can easily run into problems](#end_user_problems). Even if they already have Ruby installed, they [can still run into problems](#end_user_problems), e.g. by having the wrong Ruby version installed. The point is, it's a very real problem that [could harm your reputation](#end_user_problems).

One solution is to build OS-specific installation packages, e.g. DEBs, RPMs, .pkgs, etc. However, this has two disadvantages:

 1. It requires a lot of work. You not only have to build separate packages for each OS, but also each OS *version*. And in the context of Linux, you have to treat each distribution as another OS, further increasing the number of combinations. Suppose that you want to support ~2 versions of CentOS/RHEL, ~2 versions of Debian, ~3 versions of Ubuntu, ~2 recent OS X releases, on both x86 and x86_64. You'll have to create `(2 + 2 + 3) * 2 + 2 = 16` packages.
 2. Because you typically cannot build an OS-specific installation package using anything but that OS, you need heavyweight tooling, e.g. a fleet of VMs. For example, you can only build Ubuntu 14.04 DEBs on Ubuntu 14.04; you cannot build them from your OS X developer laptop.

This is exactly the approach that Chef has chosen. They built [Omnibus](https://github.com/opscode/omnibus), an automation system which spawns an army of VMs for building platform-specific packages. It works, but it's heavyweight and a big hassle. You need a big build machine for that if you want to have reasonable build time. And be prepared to make 20 cups of coffee.

But there is another &mdash; much simpler &mdash; solution.

### Way of the Traveling Ruby

The solution that Traveling Ruby advocates, is to distribute your app as a single self-contained tar.gz/zip package that already includes a precompiled Ruby interpreter for a specific platform (that the Traveling Ruby project provides), as well as all gems that your app depends on. This eliminates the need for heavyweight tooling:

 * A tar.gz/zip file can be created on any platform using small and simple tools.
 * You can create packages for any OS, regardless of which OS you are using.

This makes the release process much simpler. Instead of having to create more than 10 packages using a fleet of VMs, you just create 3 packages quickly and easily from your developer laptop. These 3 packages cover all the major platforms that your end users are on:

 * Linux x86.
 * Linux x86_64.
 * OS X.

(Note: Traveling Ruby [doesn't bother with supporting Windows yet](#windows_support). Sorry.)

However, distributing a precompiled Ruby interpreter that works for all end users, is more easily said than done. [Read this section](#why_precompiled_binary_difficult) to learn why it's difficult.

Traveling Ruby aims to solve the problem of supplying precompiled **Ruby 2.1** binaries that work for all end users.

## Getting started

 * [Tutorial 1: hello world](TUTORIAL-1.md) - Learn in 5 minutes how to create self-contained packages of a hello world app without gem dependencies.
 * [Tutorial 2: gem dependencies](TUTORIAL-2.md) - Managing and packaging gem dependencies using Bundler.
 * [Tutorial 3: native extensions](TUTORIAL-3.md) - Managing and packaging native extension gems.

There are also some real-world examples of how people used Traveling Ruby to package their Ruby tools:

 * **BOSH (release engineering tool)**<br>
   [Blog post](https://blog.starkandwayne.com/2014/12/24/traveling-bosh-cli-no-more-installation-pain/) | [Github repo](https://github.com/cloudfoundry-community/traveling-bosh)
 * **Elasticrawl (AWS Elastic MapReduce job runner)**<br>
   [Blog post](https://rossfairbanks.com/2015/01/13/packaging-elasticrawl-using-traveling-ruby.html) | [Github repo](https://github.com/rossf7/traveling-elasticrawl)
 * **Octodown (Github markdown preview tool)**<br>
   [Github repo](https://github.com/ianks/octodown) | [Traveling Ruby issue](https://github.com/ianks/octodown/issues/29) | [Traveling Ruby pull request](https://github.com/ianks/octodown/pull/38)

<a name="limitations"></a>

## Limitations

Traveling Ruby only supports a number of popular native extension gems, and only in some specific versions. You cannot use just any native extension gem. Native extensions are covered in [tutorial 3](TUTORIAL-3.md).

## The build system

The Traveling Ruby binaries are built using the build system in this repository.

### Linux

The build system requires Docker and `make`. To build binaries, run:

    cd linux
    ./setup-docker-image
    make

### OS X

The build system requires the Developer Tools to be installed. It has only been tested in 10.9 Mavericks. It *should* work on all OS X versions >= 10.8 Mountain Lion, but that has not been tested. To build binaries, run:

    cd osx
    make

## Future work

 * Document how the build system works.
 * Provide a Rails example. This is only possible after we've gotten a good system in place for compiling native extensions.
 * Windows support. We (Phusion) have no interest in providing Windows support for the time being, but we will welcome any pull requests for this.

## FAQ

<a name="why_precompiled_binary_difficult"></a>

### Why it is difficult to supply a precompiled Ruby interpreter that works for all end users?

Chances are that you think that you can compile a Ruby binary on a certain OS, and that users using that same OS can use your Ruby binary. Not quite. Not even when they run the same OS *version* as you do.

Basically, there are two problems that can prevent a binary from working on another system:

 1. Libraries that your binary depends on, may not be available on the user's OS.
    * When compiling Ruby, you might accidentally introduce a dependency on a non-standard library! As a developer you probably have all sorts non-standard libraries installed on your system. While compiling Ruby, the Ruby build system autodetects certain libraries and links to them.
    * Even different versions of the same OS ship with different libraries! You cannot count on a certain library from an older OS version, to be still available on a newer version of the same OS.
 2. On Linux, there are issues with glibc symbols. This is a little more complicated, so read on.

Assuming that your binary doesn't use *any* libraries besides the C standard library, binaries compiled on a newer Linux system usually do not work on an older Linux system, even if you do not use newer APIs. This is because of glibc symbols. Each function in glibc - or symbol as C/C++ programmers call it - actually has multiple versions. This allows the glibc developers to change the behavior of a function without breaking backwards compatibility with apps that happen to rely on bugs or implementation-specific behavior. During the linking phase, the linker "helpfully" links against the most recent version of the symbol. The thing is, glibc introduces new symbol versions very often, resulting in binaries that will most likely depend on a recent glibc.

There is no way to tell the compiler and linker to use older symbol versions unless you want to manually specify the version for each and every symbol, which is an undoable task.

The only sane way to get around the glibc symbol problem, and to prevent accidental linking to unwanted libraries, is to create a tightly controlled build environment. On Linux, this build environment with come with an old glibc version. This tightly controlled build environment is sometimes called a "holy build box".

The Traveling Ruby project provides such a holy build box.

#### Why not just statically link the Ruby binary?

First of all: easier said than done. The compiler prefers to link to dynamic libraries. You have to hand-edit lots of Makefiles to make everything properly link statically. You can't just add `-static` as compiler flag and expect everything to work.

Second: Ruby is incompatible with static linking. On Linux systems, executables which are statically linked to the C library cannot dynamically load shared libraries. Yet Ruby extensions are shared libraries, and a Ruby interpreter that cannot load Ruby extensions is heavily crippled.

So in Traveling Ruby we've taken a different approach. Our Ruby binaries are dynamically linked against the C library, but only uses old symbols to avoid glibc symbol problems. We also ship carefully-compiled versions of dependent shared libraries, like OpenSSL, ncurses, libedit, etc.

<a name="end_user_problems"></a>

### Why is it problematic for end users if I don't bundle a Ruby interpreter?

First of all, users just want to run your app as quickly as possible. Requiring them to install Ruby first is not only a distraction, but it can also cause problems. Here are a few examples of such problems:

 * There are various ways to install Ruby, e.g. by compiling from source, by using `apt-get` and `yum`, by using RVM/rbenv/chruby, etc. The choices are obvious to us, but users could get confused by the sheer number of choices. Worse: not all choices are good. APT and YUM often provide old versions of Ruby, which may not be the one that you want. Compiling from source and using rbenv/chruby requires the user to have a compiler toolchain and appropriate libraries pre-installed. How should they know what to pre-install before they can install Ruby? The Internet is filled with a ton of old and outdated tutorials, further increasing their confusion.
 * Users could install Ruby incorrectly, e.g. to a location that isn't in PATH. They could then struggle with "command not found" errors. PATH is obvious to us, but there are a lot of users out there can barely use the command line. We shouldn't punish them for lack of knowledge, they are end users after all.

One way to solve this is for you to "hold the user's hand", by going through the trouble of supplying 4 or 5 different platform-specific installation instructions for installing Ruby. These instructions must be continuously kept up-to-date. That's a lot of work and QA on your part, and I'm sure you just want to concentrate on building your app.

And let's for the sake of argument suppose that the user somehow has Ruby correctly installed. They still need to install your app. The most obvious way to do that is through RubyGems. But that will open a whole new can of worms:

 * On some OSes, RubyGems is configured in such a way that the RubyGems-installed commands are not in PATH. For a classic example, try running this on Debian 6:

        $ sudo apt-get install rubygems
        $ sudo gem install rails
        $ rails new foo
        bash: rails: command not found

   Not a good first impression for end users.
 * Depending on how Ruby is installed, you may or may not have to run `gem install` with `sudo`. It depends on whether `GEM_HOME` is writable by the current user or not. You can't tell them "always run with sudo", because if their `GEM_HOME` is in their home directory, running `gem install` with sudo will mess up all sorts of permissions.
 * Did I just mention `sudo`? No, because `sudo` by default resets a lot of environment variables. Environment variables which may be important for Ruby to work.
   - If the user installed Ruby with RVM, then the user has to run `rvmsudo` instead of sudo. RVM is implemented by setting `PATH`, `RUBYLIB`, `GEM_HOME` and other environment variables. rvmsudo is a wrapper around sudo which preserves these environment variables.
   - If the user installed Ruby with rbenv or chruby... pray that they know what they're doing. Rbenv and chruby also require correct `PATH`, `RUBYLIB`, `GEM_HOME` etc to be set to specific values, but they provide no rvmsudo-like tool for preserving them after taking sudo access. So if you want to be user-friendly, you have to write documentation that tells users to sudo to a bash shell first, fix their `PATH`, `RUBYLIB` etc, and *then* run `gem install`.

The point is, there's a lot of opportunity for end users to get stuck, confused and frustrated. You can deal with all these problems by supplying excellent documentation that handles all of these cases (and probably more, because there are infinite ways to break things). That's exactly what we've done for [Phusion Passenger](https://www.phusionpassenger.com). Our [RubyGems installation instructions](https://www.phusionpassenger.com/documentation/Users%20guide%20Nginx.html#rubygems_generic_install) spell out exactly how to install Ruby for each of the major operating systems, how to find out whether they need to run `gem install` with sudo, how to find out whether they need to run rvmsudo instead of sudo. It has been a lot of work, and even then we still haven't covered all the cases. We're still lacking documentation on what rbenv and chruby users should do. Right now, rbenv/chruby users regularly contact our community discussion forum about installation problems related to sudo access and environment variables.

Or you can just use Traveling Ruby and be done with it. We can't do it for Phusion Passenger because by its very nature it has to work with an already-installed Ruby, but maybe you can for writing your next command line tool.

#### The problems sound hypothetical. Is it really that big of a deal for end users?

Yes. These problems can put off your users from installing your app at all and can give you a bad reputation. Especially Chef has suffered a lot from this. A lot of people have had bad experience in the past with installing Chef through RubyGems. Chef has solved this problem for years by supplying platform-specific packages for years (DEBs, RPMs, etc), but the reputation stuck: there are still people out there who shun Chef because they think they have to install Ruby and use RubyGems.

#### I target OS X, which already ships Ruby. Should I still bundle a Ruby interpreter?

Yes. OS X versions up to 10.8 Mountain Lion ship Ruby 1.8. Only starting from 10.9 Mavericks does it ship Ruby 2.0. There are significant compatibility differences between Ruby 1.8 and 2.0. Future OS X versions might ship yet another Ruby version. Only by bundling Ruby can you be sure that OS upgrades won't break your app.

<a name="windows_support"></a>

### Why does Traveling Ruby not support Windows?

We haven't spent the effort, and we're currently not creating any tools that should run on Windows. If Windows support is important to you, feel free to open a pull request.

### How big is a hello world packaged with Traveling Ruby?

It's about 6 MB compressed.
