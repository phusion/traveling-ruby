#!/bin/sh

echo "downloading pre-packaged runtime"
if [[ "$RUBY_VERSIONS" < "3.1.0" ]]; then
    OPENSSL_SUFFIX="-openssl_1_1"
else
    OPENSSL_SUFFIX=""
fi
curl -L -o $PLATFORM/runtime.tar.gz https://github.com/YOU54F/traveling-ruby/releases/download/rel-20240201/osx-runtime-$ARCHITECTURES-gha$OPENSSL_SUFFIX.tar.gz
echo "unpacking pre-packaged runtime"
mkdir -p $PLATFORM/runtime
[[ -f "$PLATFORM/runtime.tar.gz" ]] && cd $PLATFORM && tar -xzf ../$PLATFORM/runtime.tar.gz && rm -rf ../$PLATFORM/runtime.tar.gz && echo "unpacked osx-runtime-$ARCHITECTURES.tar.gz" && ls -al ../$PLATFORM/runtime
cd ..
ls $PLATFORM
