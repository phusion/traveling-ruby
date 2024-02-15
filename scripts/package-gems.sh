#!/bin/sh

cd $PLATFORM
for file in $(find traveling-ruby-gems-* -name '*.gz'); do
  gem_name=$(echo "${file%-*}" | tr '/' '-')
  gem_version=$(echo "${file%.tar.gz}" | awk -F- '{print $NF}')
  pkg_date=$(echo "${file%-*}" | cut -d'-' -f4)
  ruby_version=$(echo "${file%-*}" | tr '/' '-' | sed -E 's/.*-([0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)?)-([a-z]+)-([a-z0-9_]+)\.tar\.gz/\1/')
  echo $ruby_version-$gem_version.tar.gz
  cp "$file" $ruby_version-$gem_version.tar.gz
done
ls -l