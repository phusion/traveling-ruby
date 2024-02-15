#!/usr/bin/env bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`

if [ -z "$1" ]; then
    echo "Usage: $0 output/<ruby-version>-<arch> <image>"
    echo "example: $0 3.2.3-arm64"
    echo "image: node:20-alpine"
    echo "image is optional|default: node:20-alpine"
    exit 1
fi
IMAGE=${2:-"node:20-alpine"}
if ! command -v docker &> /dev/null
then
        echo "Error: docker could not be found"
        exit 1
fi

ARCH=$(echo $1 | sed -E 's/output\///' | sed 's/.*-//')
RUBY_VERSION=$(echo $1  | sed -E 's/(-arm64|-x86_64)//' | sed -E 's/output\///')
echo "ARCH: $ARCH"
echo "RUBY_VERSION: $RUBY_VERSION"

# ## override for docker platform
[ "$ARCH" == "x86_64" ] && ARCH="amd64"

echo docker run --platform linux/"${ARCH}" --rm --entrypoint /bin/sh -v $SELFDIR/..:/home "${IMAGE}" -c "apk add bash && ./home/shared/test-gems.sh home/alpine/"$@"";

docker run --platform linux/"${ARCH}" --rm --entrypoint /bin/sh -v $SELFDIR/..:/home "${IMAGE}" -c "apk add bash && ./home/shared/test-gems.sh home/alpine/"$@"";
