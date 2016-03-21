# Tutorial 4: creating packages for Windows

In the previous tutorials we covered [the basics](TUTORIAL-1.md), [gem dependencies](TUTORIAL-2.md) and [native extensions](TUTORIAL-3.md). But we never covered Windows support. That's because the flow for Windows support is a bit different from other platforms, so it deserves its own tutorial.

But there are several [**important Windows-specific caveats**](README.md#caveats). You should read them before proceeding with this tutorial!!

You can find the end result of this tutorial at https://github.com/phusion/traveling-ruby-windows-demo.

## Creating a batch file

Suppose that we want to create a Windows package for our hello world app from [tutorial 2](TUTORIAL-2.md). The first thing we need to create is a Windows wrapper script. We already have a Unix wrapper script in `packaging/wrapper.sh`, which works on Linux and OS X, but Windows doesn't support Unix shell scripts. For Windows we'll need to create a wrapper script in the DOS batch format.

Create `packaging/wrapper.bat`:

```Batch
@echo off

:: Tell Bundler where the Gemfile and gems are.
set "BUNDLE_GEMFILE=%~dp0lib\vendor\Gemfile"
set BUNDLE_IGNORE_CONFIG=

:: Run the actual app using the bundled Ruby interpreter, with Bundler activated.
@"%~dp0lib\ruby\bin\ruby.bat" -rbundler/setup "%~dp0lib\app\hello.rb"
```

## Modifying the Rakefile

The next step is to add a Rake task for creating the Windows package. The Rakefile currently generates tar.gz packages for Linux and OS X, but tar.gz is not a common format on Windows. For Windows, we'll want to create a .zip package instead.

Add a `package:win32` task to your Rakefile:

```Ruby
namespace :package do
  ...

  desc "Package your app for Windows x86"
  task :win32 => [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-win32.tar.gz"] do
    create_package("win32", :windows)
  end
```

Add a task for downloading the Traveling Ruby Windows binaries:

```Ruby
file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-win32.tar.gz" do
  download_runtime("win32")
end
```

We must update the `create_package` method so that it generates the package slightly differently depending on the target platform. Update its signature and add a `os_type = :unix` parameter:

```Ruby
def create_package(target, os_type = :unix)
```

This method contains a line which copies `wrapper.sh`, but we'll want to copy `wrapper.bat` when creating Windows packages. 

```Ruby
# Look for:
sh "cp packaging/wrapper.sh #{package_dir}/hello"

# Replace it with:
if os_type == :unix
  sh "cp packaging/wrapper.sh #{package_dir}/hello"
else
  sh "cp packaging/wrapper.bat #{package_dir}/hello.bat"
end
```

There is a line which creates the final tar.gz file. We'll want to modify this so that a .zip file is created when targeting Windows.

```Ruby
# Look for:
sh "tar -czf #{package_dir}.tar.gz #{package_dir}"

# Replace it with:
if os_type == :unix
  sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
else
  sh "zip -9r #{package_dir}.zip #{package_dir}"
end
```

Finally, add the `package:win32` task to the `package` task's dependencies so that a `rake package` generates a Windows package too:

```Ruby
task :package => ['package:linux:x86', 'package:linux:x86_64', 'package:osx', 'package:win32']
```

## Creating and testing the package

Congratulations. The `rake package` command will now generate packages for Windows, Linux and OS X. But let's test the Windows package. Run the following command to generate a Windows package:

```Bash
rake package:win32
```

This will generate `hello-1.0.0-win32.zip`. Copy this file to a Windows machine and extract it to `C:\`. Then open a `cmd.exe` command prompt and test it:

```
C:\Users\Test> cd C:\hello-1.0.0-win32
C:\hello-1.0.0-win32> hello
hello Mrs. Mellie Ebert
```

## Conclusion

Congratulations, you've learned how to create packages for Windows! You've now reached the end of this tutorial series and you now master the basics of Traveling Ruby. You can find the end result of this tutorial at https://github.com/phusion/traveling-ruby-windows-demo.

Next up, you may want to read [the guides](README.md#getting-started), which cover intermediate to advanced topics.
