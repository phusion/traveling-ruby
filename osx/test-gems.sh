#!/bin/bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
exec "$SELFDIR/../shared/test-gems.sh" "$@"