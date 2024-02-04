#!/bin/sh

if [[ "$RUBY_VERSIONS" < "3.1.0" ]]; then
    OPENSSL_SUFFIX="-openssl_1_1"
else
    OPENSSL_SUFFIX=""
fi
cd $PLATFORM && tar -czvf $PLATFORM-runtime-$ARCHITECTURES$OPENSSL_SUFFIX.tar.gz runtime