# Traveling Ruby: portable Ruby binaries

Traveling Ruby is a project which supplies self-contained, "portable" Ruby binaries: Ruby binaries that can run on any Linux distribution and any OS X machine.

[Normally you have to compile Ruby on each version of the target OS/distribution](#why_compile_for_each_os_version) (multiple versions of Fedora, multiple versions of Debian, multiple versions of OS X, etc). But the binaries supplied by this project work on any version of a target OS. The goal of this project is to make it viable to use Ruby for writing software for non-Ruby-programmer end users, without needing the developer to go through a lot of trouble with packaging for each OS version and architecture.

This doesn't mean that a single binary can run on both Linux and OS X. Traveling Ruby supplies three sets of Ruby binaries:

 * Linux x86 - can run on any x86 Linux distribution, and any x86_64 Linux distribution that has 32-bit compatibility libraries installed.
 * Linux x86_64 - can run on any x86_64 Linux distribution.
 * OS X - can run on any OS X version.

Here, "any" in the context of Linux means at least CentOS 5 and Ubuntu 10.04. In the context of OS X, it means at least 10.8 Mountain Lion (implying x86_64).

## Motivation and background

Ruby is one of our favorite programming langugages. Most people use it for web development, but Ruby is so much more. We at Phusion have been using Ruby for years for writing sysadmin automation scripts, developer command line tools and more. Heroku's Toolbelt and Chef have also demonstrated that Ruby is an excellent language for these sorts of things.

However, distributing your Ruby app to inexperienced or non-Ruby-programmer end users is a problem. With languages like Go, you can (cross-)compile single executables that end users can just run. But if your app is written in Ruby then end users have to install Ruby first, and (if you didn't supply your app in any other way) they have to work with RubyGems to install your app. This introduces many problems:

 * You have to pray that they installed Ruby correctly, and installed the correct Ruby version.
 * `gem install` is obvious for Ruby programmers, but non-Ruby-programmer end users often struggle with it.

Chances are that you think "So what? These are minor problems". I've left out specific examples in this section for the sake of brevity, but you should read [Examples of end-user problems](#examples_of_end_user_problems) to learn why these are, in fact, significant problems.

Anyway, the point is that there are problems that can put off your users from installing your app at all. Especially Chef has received a bad reputation for this: some people shun Chef because they think they have to install Ruby first, and a lot of people have had bad experience with installing Chef through RubyGems. This bad reputation stuck: Chef has supplied platform-specific packages for years (DEBs, RPMs, etc), but there are still many users out there who still think Chef has to be installed through RubyGems.

One way to solve this problem is by building platform-specific packages. However, this requires a lot of work. As we stated before, [it's necessary to build different binaries for each OS version](#why_compile_for_each_os_version). You have to build a different RPM for each Fedora, CentOS and Red Hat version. You have to build a different DEB for each Debian and Ubuntu version. You have to build a different package for every OS X version. Double this number if you want to support both x86 and x86_64. With at least ~2 versions of supported Red Hat-based distributions, ~5 versions of supported Ubuntu versions and ~2 recent OS X releases, you end up having to create `2 * 5 * 2 * 2 = 40` packages. That's insane, to say the least. And we've only covered the major Linux distributions: if you want to support Gentoo, Arch, etc then the combinatorial explosion explodes even further.

Yet Chef has chosen exactly this approach. They built [Omnibus](https://github.com/opscode/omnibus), an automation system which spawns an army of VMs for building platform-specific packages. It works, but it's heavyweight and a big hassle. You need a big build machine for that if you want to have reasonable build time. And be prepared to make 20 cups of coffee.

Let's take a step back and look at Go. Go allows you to compile a statically linked binary for any of its supported platforms, regardless of which platform you are running on. You could compile a Linux binary while running on OS X. And this binary would run on all Linux distributions. Or you could compile an OS X binary, and it would work on all OS X versions. **This is beautifully simple.** Can't we take the same approach for Ruby?

That's where Traveling Ruby comes in. This project supplies binaries that can work on any Linux version, any OS X version. You create just 3 tar.gz/zip packages for your app: x86 Linux, x86_64 Linux, OS X. In each package, you insert your app's Ruby code, plus the corresponding Traveling Ruby binaries, plus a shell script that starts your app using the Traveling Ruby binary. And that's it: you've created end-user packages for all major operating systems (excluding Windows). Users can just run the shell script inside the package and your app will just work. Like the Go approach, this is beautifully simple: you don't have to spawn any VMs, and you can cross-build packages for any of your target OSes, regardless of which OS you are running on.

## Using the binaries

To be written.

Suffice to say for now that you can use any Ruby gems, subject to the documented limitations.

### Packaging your app

To be written.

## Limitations

To be written.

 * You cannot use gems with native extensions. Well technically you can, but then you have to compile for 3 different platforms. I haven't documented this yet.

## FAQ

<a name="why_compile_for_each_os_version"></a>

### Why it's necessary to compile Ruby for each OS version

We stated earlier that it's necessary to compile Ruby not just for each OS, but also each OS *version*. Why is that? You might be wondering why you can't just build on some "Linux" OS and have the binary work on all other Linux-based OSes. And even if there are large differences between different Linux distributions, surely you can just build on one distribution (maybe an older version) and expect the binary to work on other versions of the same distribution? Not so, and not on OS X either.

Basically, there are two problems:

 1. Libraries that your binary depends on, may not be available on other Linux distributions or even other versions of the same distribution. The same is true for OS X.
 2. On Linux, there are issues with glibc symbols. This is a little more complicated, so read on.

Assuming that your binary doesn't use *any* libraries besides the C standard library, binaries compiled on a newer Linux system usually do not work on an older Linux system, even if you do not use newer APIs. This is because of glibc symbols. Each function in glibc - or symbol as C/C++ programmers call it - actually has multiple versions. This allows the glibc developers to change the behavior of a function without breaking backwards compatibility with apps that happen to rely on bugs or implementation-specific behavior. During the linking phase, the linker "helpfully" links against the most recent version of the symbol. The thing is, glibc introduces new symbol versions very often, resulting in binaries that will most likely depend on a recent glibc.

There is no way to tell the compiler and linker to use older symbol versions unless you want to manually specify the version for each and every symbol, which is an undoable task. The only sane way to get around this is to create a tightly controlled build environment with an old glibc, a "holy build box" if you will.

The Traveling Ruby project provides such a holy build box.

### Why not just statically link the Ruby binary?

First of all: easier said than done. The compiler prefers to link to dynamic libraries. You have to hand-edit lots of Makefiles to make everything properly link statically. You can't just add `-static` as compiler flag and expect everything to work.

Second: Ruby is incompatible with static linking. On Linux systems, executables which are statically linked to the C library cannot dynamically load shared libraries. Yet Ruby extensions are shared libraries, and a Ruby interpreter that cannot load Ruby extensions is heavily crippled.

So in Traveling Ruby we've taken a different approach. Our Ruby binaries are dynamically linked against the C library, but only uses old symbols to avoid glibc symbol problems. We also ship carefully-compiled versions of dependent shared libraries, like OpenSSL, ncurses, libedit, etc.

<a name="examples_of_end_user_problems"></a>

### Examples of end-user problems

If the user has to install Ruby, then they can run into all sorts of trouble:

 * Installation instructions are platform-specific. Users just want to run your app as quickly as possible. So if you want to be user-friendly, instead of just pointing to ruby-lang.org, you should supply 4 or 5 different platform-specific installation instructions for installing Ruby. And keep them up-to-date. This is a lot of work and QA on your part.
 * If users installed Ruby incorrectly, e.g. to a location that isn't in PATH, they could struggle with "command not found" errors. PATH is obvious to us, but there are a lot of users out there can barely use the command line. We shouldn't punish them for lack of knowledge, they are end users after all.
 * If they already have a different version of Ruby installed, it can be incompatible with your app. If they install the Ruby version you need then they can end up with multiple Ruby versions, which not only confuses them but can also conflict with each other. For example, some *other* apps on their system which was running a different Ruby version before (with its own gems), now suddenly run as the newly installed Ruby version, where all sorts of gems might be missing. This breaks a lot of stuff.

If the user has to use RubyGems to install your app then it can cause a lot of confusion and frustration:

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

As you can see, there's a lot of opportunity for end users to get stuck, confused and frustrated. You can deal with all these problems by supplying excellent documentation that handles all of these cases (and probably more, because there are infinite ways to break things). That's exactly what we've done for [Phusion Passenger](https://www.phusionpassenger.com). Our [RubyGems installation instructions](https://www.phusionpassenger.com/documentation/Users%20guide%20Nginx.html#rubygems_generic_install) spell out exactly how to install Ruby for each of the major operating systems, how to find out whether they need to run `gem install` with sudo, how to find out whether they need to run rvmsudo instead of sudo. It has been a lot of work, and even then we still haven't covered all the cases. We're still lacking documentation on what rbenv and chruby users should do. Right now, rbenv/chruby users regularly contact our community discussion forum about installation problems related to sudo access and environment variables.

Or you can just use Traveling Ruby and be done with it. We can't do it for Phusion Passenger because by its very nature it has to work with an already-installed Ruby, but maybe you can for writing your next command line tool.
