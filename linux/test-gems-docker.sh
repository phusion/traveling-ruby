#!/usr/bin/env bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`

if [ -z "$1" ]; then
    echo "Usage: $0 <ruby-version>-<arch>"
    echo "example: $0 3.2.2-arm64"
    exit 1
fi

# Split ruby-version-arch into values
RUBY_VERSION=$(echo $1 | cut -d'-' -f1)
ARCH=$(echo $1 | cut -d'-' -f2)

# If ARCH is x86_64 update to amd64
if [ "$ARCH" == "x86_64" ]; then
    ARCH="amd64"
fi

if ! command -v docker &> /dev/null
then
        echo "Error: docker could not be found"
        exit 1
fi


docker run --platform linux/$ARCH --rm --entrypoint /bin/bash -v $SELFDIR/..:/home node:20-slim -c "./home/shared/test-gems.sh home/linux/output/"$@"";