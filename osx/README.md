# Traveling Ruby OS X build system

The build system requires the Developer Commandline Tools to be installed, as well as the OS X 10.8 SDK.

To build binary packages, run:

    cd osx
    rake

You can view all tasks by running `rake -T`.

## Installing the OS X 10.8 SDK

You are required to use an older version of Xcode as you need to have the OS X 10.8 SDK installed locally. You can install Xcode 5.1.1 as follows.

### The automated way

Install [xcode-install](https://github.com/neonichu/xcode-install) using

```
[sudo] gem install xcode-install
```

```
xcversion update
xcversion install 5.1.1
```

This will install the old Xcode release in `/Applications/Xcode-5.1.1.app`.

To copy over the SDK from the old Xcode to the new one, just run

```
rake install_sdk
```

### The manual way

#### 1. Download Xcode 5.1.1

Open the [Developer Portal download page](https://developer.apple.com/downloads/) and login with your Apple account. When you see the list of downloads, just open the [xcode_5.1.1.dmg link](http://adcdownload.apple.com/Developer_Tools/xcode_5.1.1/xcode_5.1.1.dmg) in your browser.

#### 2. Show Xcode package contents

![](https://raw.githubusercontent.com/phusion/traveling-ruby/master/doc/xcodepackage.jpg)

Open the Xcode .dmg file. Right click on Xcode.app and choose "Show Package Contents".

#### 3. Locate OS X 10.8 SDK and copy it to the system

![](https://raw.githubusercontent.com/phusion/traveling-ruby/master/doc/sdk.jpg)

Locate the OS X 10.8 SDK inside the Xcode package contents. Copy this directory to /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/.
