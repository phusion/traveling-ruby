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

### Disabling System Integrity Protection

Our build system depends on `DYLD_FALLBACK_LIBRARY_PATH`. This [doesn't work while System Integrity Protection is enabled](https://stackoverflow.com/a/35570229/20816), so you must disable it before building. You may re-enable it after building.

 1. Reboot your system into recovery mode (hold ⌘+R on reboot)

 2. When the "macOS Utilities" screen appears, pull down the "Utilities" menu at the top of the screen instead, and choose "Terminal".

 3. Disable System Integrity Protection, then reboot back into normal mode:

    ~~~bash
    csrutil disable
    reboot
    ~~~

 4. Verify that System Integrity Protection is disabled. Run `csrutil status`, which should output:

    ~~~
    System Integrity Protection status: disabled.
    ~~~

 5. When you're done building Traveling Ruby, go back to recovery mode and run this in its terminal to fully reenable System Integrity Protection:

    ~~~bash
    csrutil enable
    reboot
    ~~~

Note: we've verified that *partially* disabling System Integrity Protected is not enough to make `DYLD_*` variables work. Only *fully* disabling it seems to do the job.
