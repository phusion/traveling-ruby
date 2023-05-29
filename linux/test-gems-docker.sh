#!/usr/bin/env bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`

if [ -z "$1" ]; then
    echo "Usage: $0 <ruby-version>-<arch>"
    echo "example: $0 3.2.2-arm64"
    echo "example: $0 3.2.2-preview1-arm64"
    # RUBY_VERSION: 3.2.2-preview1
    # ARCH: arm64
    # RUBY_VERSION: 3.2.2
    # ARCH: arm64
    exit 1
fi

# Split ruby-version-arch into values
# ./linux/test-gems-docker.sh output/3.2.2-foo-arm64
# ./linux/test-gems-docker.sh output/3.2.2-arm64

# result

# RUBY_VERSION: 3.2.2-foo
# ARCH: arm64

# RUBY_VERSION: 3.2.2
# ARCH: arm64


ARCH=$(echo $1 | awk -F'/' '{print $NF}' | awk -F'-' '{print $NF}')
RUBY_VERSION=$(echo $1 | awk -F'/' '{print $NF}' | awk -F'-' '{print $1 $2}')

echo "RUBY_VERSION: $RUBY_VERSION"
echo "ARCH: $ARCH"

# # If ARCH is x86_64 update to amd64
# if [ "$ARCH" == "x86_64" ]; then
#     ARCH="amd64"
# fi

# if ! command -v docker &> /dev/null
# then
#         echo "Error: docker could not be found"
#         exit 1
# fi


# docker run --platform linux/"$ARCH" --rm --entrypoint /bin/bash -v $SELFDIR/..:/home node:20-slim -c "./home/shared/test-gems.sh home/linux/"$@"";