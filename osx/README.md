# Traveling Ruby OS X build system

The build system requires the Developer Commandline Tools to be installed, as well as a number of other things. 

See the "System requirements" section.

To build binary packages for `arm64`, run:

    cd osx
    ARCHITECTURES=arm64 rake

To build binary packages for `x86_64`, run:

    cd osx
    ARCHITECTURES=x86_64 rake

You can view all tasks by running `rake -T`.

## System requirements

- `x86_64` or `arm64`
- MacOS minimum deployment target `12.2`

### Install Xcode Command Line Tools 
- Copy and paste the following text into your terminal _(and press **"return"**)_: 
```
xcode-select --install
```
- Follow the prompts.

****

### Cross-Compiling

In order to cross-compile for `x86_64` from `arm64` hosts, you _must_ install Rosetta.

- `sudo softwareupdate --install-rosetta --agree-to-license`

_Note:_ You don't need to run in a Rosetta enabled shell or prefix your command with `-arch x86_64`, setting the `ARCHITECTURES` value to `x86_64` is sufficient.

 <!-- 
 
 TODO:- Are these still needed?
 
 1. Download the SDK at [phracker/MacOSX-SDKs](https://github.com/phracker/MacOSX-SDKs).
 1. Extract with: `sudo tar -xf MacOSX10.14.sdk.tar.xz -C "$(xcode-select -p)/Platforms/MacOSX.platform/Developer/SDKs"`
 2. Modify the XCode MacOSX.Platform/Info.plist file.

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
        ~~~ -->

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
