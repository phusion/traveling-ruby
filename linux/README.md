# Traveling Ruby Linux build system

The `linux/` directory contains the build system for building Traveling Ruby binaries for Linux.

## Building binaries

The build system requires Docker and Rake. To build binaries, run:

    cd linux
    rake

This will produce a `traveling-ruby-XXXXX.tar.gz` file which contains the Ruby binaries, and a `traveling-ruby-gems-XXXXX` directory which contains the native extensions.

## How it works

### Build environment (Docker image)

The build system runs inside a Docker container. The Docker image is called [phusion/traveling-ruby-builder](https://registry.hub.docker.com/r/phusion/traveling-ruby-builder/), and it's built from the sources in `linux/image/`.

The image contains a controlled build environment with a specific compiler toolchain and specific libraries, allowing us to compile binaries that can run on a large number of Linux systems. It's based on [Holy Build Box](http://phusion.github.io/holy-build-box/).

The image can be built with `rake image`.

### Build script

The build script is the component that actually compiles Ruby. It assumes that the build environment is already available.

The build script consists of two parts:

 1. `linux/build-ruby` is the entrypoint for users. It spawns a Docker container, based on the build environment Docker image. Inside the container, it runs `linux/internal/build-ruby`.

 2. `linux/internal/build-ruby` is the script that contains most of the actual build logic. It:

     * Builds Ruby. It extracts the Ruby source tarball and runs `./configure`, `make` and `make install`.
     * Builds the native extensions that Traveling Ruby supports. It runs `bundle install` on the Gemfile located in the `shared/` directory in the Traveling Ruby repository.
     * Performs various postprocessing tasks, such as stripping debugging symbols from the binaries and running various sanity checks.

You can kick off the build script with `rake build`. The build outputs are saved to the `output` directory.

### Package script

Once binaries are compiled, once can package the files by invoking `rake package`. This script packages files inside the `output` directory into various tarballs.
