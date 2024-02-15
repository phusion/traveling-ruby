#!/usr/bin/env bash
set -e
set -o pipefail
if [[ $(uname) == "Darwin" ]]; then
    # get the internal CPU count from docker when running
    # on macOS. This is how many CPUs the user has assigned
    # which is different from the number of CPUs on the host
    docker system info --format '{{.NCPU}}'
else
   grep "`echo -en 'processor\t'`" /proc/cpuinfo | wc -l
fi