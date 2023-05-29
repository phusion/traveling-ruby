#!/bin/bash
# set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/library.sh"

ls -1 output | xargs -I '{}' ../shared/test-gems.sh ../osx/output/'{}'

#  | xargs -I '{}' ./test-gems.sh output/'{}'
