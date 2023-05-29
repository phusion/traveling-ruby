#!/usr/bin/env bash
set -e
set -o pipefail
if [[ $(uname) == "Darwin" ]]; then
    sysctl -n hw.ncpu
else
   grep "`echo -en 'processor\t'`" /proc/cpuinfo | wc -l
fi