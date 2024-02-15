#!/usr/bin/env bash
set -e

# This script lists the available versions of Traveling Ruby builds for different operating systems.
# Usage: ./list-versions.sh [all|windows|linux|osx] [unpack]
# - all: lists all available builds for all operating systems.
# - windows: lists all available builds for Windows.
# - linux: lists all available builds for Linux.
# - osx: lists all available builds for macOS.
# - unpack: if specified as the second argument, unpacks the selected build(s) to the output directory.

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/library.sh"

list_output_builds() {
  # echo "| -------------- | ---------- |   ------------   | ------- |  ------ |"
  # echo "|    name        |  pkg_date  |   ruby_version   |    os   |   arch  |"
  # echo "| -------------- | ---------- |   ------------   | ------- |  ------ |"
  # ls -1 *.tar.gz | awk -F'[-.]' '{if (NF==11) printf "%-15s %-8s %-12s %-6s %s\n", " |" $1 "-" $2,"| " $3,"| " $4 "." $5 "." $6 "-" $7,"| " $8,"| " $9" | "; else printf "%-15s %-8s %-12s %-6s %s\n", "|" $1 "-" $2," | "  $3,"| "  $4 "." $5 "." $6,"| " $7, "| " $8" | " }' | sort -nr | column -t
  rm -f output.txt
  echo "name pkg_date ruby_version os arch size" >> output.txt;
  echo "--- -------- -------------- -- ---- ----" >> output.txt;
  ls -1 *.tar.gz | while read file; do
    name=$(echo $file | cut -d'-' -f1-2)
    pkg_date=$(echo $file | cut -d'-' -f3)
    ruby_version=$(echo "$file" | sed -E 's/.*-([0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)?)-([a-z]+)-([a-z0-9_]+)\.tar\.gz/\1/')
    [[ "$ruby_version" == *"-"* ]] && os=$(echo $file | cut -d'-' -f6) || os=$(echo $file | cut -d'-' -f5)
    [[ "$ruby_version" == *"-"* ]] && arch=$(echo $file | cut -d'-' -f7 | cut -d'.' -f1) || arch=$(echo $file | cut -d'-' -f6 | cut -d'.' -f1)
    size=$(du -h $file | cut -f1)
    echo "$name $pkg_date $ruby_version $os $arch $size" >> output.txt;
    if [[ ${2:-} == "unpack" ]]; then
      echo "unpacking to output/$ruby_version-$arch"
      mkdir -p "output/$ruby_version-$arch"
      tar -xzf "$file" -C "output/$ruby_version-$arch"
    fi
  done
  cat output.txt

}

# Check the first argument to determine which operating system to list builds for.
# If no argument is provided, exit with an error message.
if [[ ${1:-} == "all" ]]; then
  cd $SELFDIR/../osx
  list_output_builds "" $2
  cd $SELFDIR/../windows
  list_output_builds "" $2
  cd $SELFDIR/../linux
  list_output_builds "" $2
elif [[ ${1:-} != "" ]]; then
  if [[ "$1" != "windows" && "$1" != "linux" && "$1" != "osx" ]]; then
    echo "Invalid argument: $1. Please enter 'windows', 'linux', or 'osx'."
    exit 1
  fi
  cd $SELFDIR/../$1
  list_output_builds "" $2
else
  echo "Usage: ./list-versions.sh [all|windows|linux|osx] [unpack]"
  exit 1
fi
