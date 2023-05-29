#!/bin/bash

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/library.sh"

test_all_gems(){
    ls -1 $SELFDIR/../$1/output
    ls -1 $SELFDIR/../$1/output | xargs -I '{}' $SELFDIR/test-gems.sh $SELFDIR/../$1/output/'{}'
}

if [[ ${1:-} != "" ]]; then
  if [[ "$1" != "windows" && "$1" != "linux" && "$1" != "osx" ]]; then
    echo "Invalid argument: $1. Please enter 'windows', 'linux', or 'osx'."
    exit 1
  fi
  test_all_gems $1   
fi