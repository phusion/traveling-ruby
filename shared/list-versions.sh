#!/usr/bin/env bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/library.sh"

list_output_builds() {
  echo "| -------------- | ---------- |   ------------   | ------- |  ------ |"
  echo "|    name        |  pkg_date  |   ruby_version   |    os   |   arch  |"
  echo "| -------------- | ---------- |   ------------   | ------- |  ------ |"
  ls -1 *.tar.gz | awk -F'[-.]' '{if (NF==11) printf "%-15s %-8s %-12s %-6s %s\n", " |" $1 "-" $2,"| " $3,"| " $4 "." $5 "." $6 "-" $7,"| " $8,"| " $9" | "; else printf "%-15s %-8s %-12s %-6s %s\n", "|" $1 "-" $2," | "  $3,"| "  $4 "." $5 "." $6,"| " $7, "| " $8" | " }' | sort -nr | column -t
}





if [[ ${1:-} == "" ]]; then
  list_output_builds
elif [[ ${1:-} == "all" ]]; then
  cd ../osx
  list_output_builds
  cd ../windows
  list_output_builds
  cd ../linux
  list_output_builds
elif [[ ${1:-} != "" ]]; then
  if [[ "$1" != "windows" && "$1" != "linux" && "$1" != "osx" ]]; then
    echo "Invalid argument: $1. Please enter 'windows', 'linux', or 'osx'."
    exit 1
  fi
  cd ../$1
  list_output_builds
fi



