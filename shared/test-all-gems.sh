#!/bin/bash

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/library.sh"

# Function to display usage instructions
usage() {
  echo "Usage: $0 [windows|linux|osx]"
  echo "Test all gems for the specified platform."
  echo "  windows: Test all gems for Windows platform."
  echo "  linux: Test all gems for Linux platform."
  echo "  osx: Test all gems for macOS platform."
}
echo "Source is $0"
echo "SELFDIR is $SELFDIR"
echo "User input is $1"
ls $SELFDIR
ls $SELFDIR/../$1

# Function to test all gems for the specified platform
test_all_gems(){
    ls -1 $SELFDIR/../$1/output
    ls -1 $SELFDIR/../$1/output | xargs -I '{}' $SELFDIR/test-gems.sh $SELFDIR/../$1/output/'{}'
}

# Check if an argument is provided
if [[ ${1:-} != "" ]]; then
  # Check if the argument is valid
  if [[ "$1" != "windows" && "$1" != "linux" && "$1" != "osx" ]]; then
    echo "Invalid argument: $1. Please enter 'windows', 'linux', or 'osx'."
    usage
    exit 1
  fi
  test_all_gems $1   
else
  usage
fi