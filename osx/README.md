# Traveling Ruby OS X build system

The build system requires the Developer Commandline Tools to be installed, as well as the OS X 10.8 SDK.

To build binaries, run:

    cd osx
    make

## Installing the OS X 10.8 SDK

The OS X 10.8 SDK is included in Xcode 5. If you are using a newer version of Xcode then you can install it as follows.

### 1. Download Xcode 5.1.1

![](https://raw.githubusercontent.com/phusion/traveling-ruby/master/doc/download_xcode.jpg)

Go to the Apple Developer website and download Xcode 5.1.1.

### 2. Show Xcode package contents

![](https://raw.githubusercontent.com/phusion/traveling-ruby/master/doc/xcodepackage.jpg)

Open the Xcode .dmg file. Right click on Xcode.app and choose "Show Package Contents".

### 3. Locate OS X 10.8 SDK and copy it to the system

![](https://raw.githubusercontent.com/phusion/traveling-ruby/master/doc/sdk.jpg)

Locate the OS X 10.8 SDK inside the Xcode package contents. Copy this directory to /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/.