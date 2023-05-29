#!/usr/bin/env bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/library.sh"


ls -1 *.tar.gz | while read file; do
  version=$(echo "$file" | sed -E 's/.*-([0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)?)-([a-z]+)-([a-z0-9]+)\.tar\.gz/\1/')
  arch=$(echo "$file" | sed -E 's/.*-([0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)?)-([a-z]+)-([a-z0-9]+)\.tar\.gz/\4/')
  echo $version
  echo $arch
  echo "unpacking to output/$version-$arch"
  mkdir -p "output/$version-$arch"
  tar -xzf "$file" -C "output/$version-$arch"
done