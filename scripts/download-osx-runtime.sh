#!/bin/sh

echo "downloading pre-packaged runtime"
curl -L -o $PLATFORM/runtime.tar.gz https://github.com/YOU54F/traveling-ruby/releases/download/rel-20240116/osx-runtime-$ARCHITECTURES.tar.gz
echo "unpacking pre-packaged runtime"
mkdir -p $PLATFORM/runtime
[[ -f "$PLATFORM/runtime.tar.gz" ]] && cd $PLATFORM && tar -xzf ../$PLATFORM/runtime.tar.gz && rm -rf ../$PLATFORM/runtime.tar.gz && echo "unpacked osx-runtime-$ARCHITECTURES.tar.gz" && ls -al ../$PLATFORM/runtime
cd ..
ls $PLATFORM
