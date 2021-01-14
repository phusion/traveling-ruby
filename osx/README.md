# Traveling Ruby OS X build system

The build system requires the Developer Commandline Tools to be installed, as well as a number of other things. See the "System requirements" section.

To build binary packages, run:

    cd osx
    rake

You can view all tasks by running `rake -T`.

## System requirements

### MacOS 10.14 SDK

You are required to install the macOS 10.14 SDK so that we can build binaries that run on older macOS versions.

 1. Download the SDK at [phracker/MacOSX-SDKs](https://github.com/phracker/MacOSX-SDKs).
 2. Extract with: `sudo tar -xf MacOSX10.14.sdk.tar.xz -C "$(xcode-select -p)/Platforms/MacOSX.platform/Developer/SDKs"`
 3. Modify the XCode MacOSX.Platform/Info.plist file.

     1. Make the file and its containing directory writable by non-root:

        ~~~bash
        sudo chown "$(id -u)" "$(xcode-select -p)/Platforms/MacOSX.platform/Info.plist"
        sudo chown "$(id -u)" "$(xcode-select -p)/Platforms/MacOSX.platform"
        ~~~

     2. Open the file in Xcode:

        ~~~bash
        open "$(xcode-select -p)/Platforms/MacOSX.platform/Info.plist"
        ~~~

     3. Set `MinimumSDKVersion` to 10.14 or lower.

     4. Restore original permissions:

        ~~~bash
        sudo chown root "$(xcode-select -p)/Platforms/MacOSX.platform/Info.plist"
        sudo chown root "$(xcode-select -p)/Platforms/MacOSX.platform"
        ~~~

### Clearing certain paths

To prevent pollution of the build environment, you must ensure that the following files/directory do not exist while building:

 * ~/.bundle/config
 * /usr/local/include
 * /usr/local/lib

You can temporary rename these paths before building...

~~~bash
rake stash_conflicting_paths
~~~

...then restoring them after building:

~~~bash
rake unstash_conflicting_paths
~~~
