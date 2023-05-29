#!/usr/bin/env bash
set -e

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
    # rm output.txt
    # echo "unpacking to output/$version-$arch"
    # mkdir -p "output/$version-$arch"
    # tar -xzf "$file" -C "output/$version-$arch"
  done
  cat output.txt | column -t

}





if [[ ${1:-} == "all" ]]; then
  cd $SELFDIR/../osx
  list_output_builds
  cd $SELFDIR/../windows
  list_output_builds
  cd $SELFDIR/../linux
  list_output_builds
elif [[ ${1:-} != "" ]]; then
  if [[ "$1" != "windows" && "$1" != "linux" && "$1" != "osx" ]]; then
    echo "Invalid argument: $1. Please enter 'windows', 'linux', or 'osx'."
    exit 1
  fi
  cd $SELFDIR/../$1
  list_output_builds
fi




