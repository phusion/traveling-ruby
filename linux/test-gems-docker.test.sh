# BEGIN: ed8c6549bwf9
# Split ruby-version-arch into values
# ./linux/test-gems-docker.sh output/3.2.2-foo-arm64
# ./linux/test-gems-docker.sh output/3.2.2-arm64

# result

# RUBY_VERSION: 3.2.2-foo
# ARCH: arm64

# RUBY_VERSION: 3.2.2
# ARCH: arm64


if [ -z "$1" ]; then
    echo "Usage: $0 <ruby-version>-<arch>"
    echo "example: $0 3.2.2-arm64"
    exit 1
fi

ARCH=$(echo $1 | awk -F'/' '{print $NF}' | awk -F'-' '{print $NF}')
RUBY_VERSION=$(echo $1 | awk -F'/' '{print $NF}' | awk -F'-' '{print $2}')

echo "RUBY_VERSION: $RUBY_VERSION"
echo "ARCH: $ARCH"
# END: ed8c6549bwf9