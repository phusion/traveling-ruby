#!/usr/bin/env bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`

RUNTIME_DIR=

function usage()
{
	echo "Usage: ./shell.sh [options] <RUNTIME DIR>"
	echo "Open a shell for the specified runtime directory."
	echo
	echo "Options:"
	echo "  -h      Show this help"
}

function parse_options()
{
	local OPTIND=1
	local opt
	while getopts "h" opt; do
		case "$opt" in
		h)
			usage
			exit
			;;
		*)
			return 1
			;;
		esac
	done

	(( OPTIND += 1 )) || true
	shift $OPTIND || true
	RUNTIME_DIR="$1"

	if [[ "$RUNTIME_DIR" = "" ]]; then
		usage
		exit 1
	fi
	if [[ ! -e "$RUNTIME_DIR" ]]; then
		echo "ERROR: $RUNTIME_DIR doesn't exist."
		exit 1
	fi
}


parse_options "$@"
RUNTIME_DIR=`cd "$RUNTIME_DIR" && pwd`
mkdir -p "$RUNTIME_DIR/mock"

echo "Within the shell, you can the mock environment with:"
if [[ -e "$RUNTIME_DIR/mock/epel-5-i386" ]]; then
	echo "  /usr/bin/mock -r epel-5-i386 --shell"
else
	echo "  /usr/bin/mock -r epel-5-x86_64 --shell"
fi

exec docker run \
	--rm -t -i \
	--cap-add SYS_ADMIN --cap-add SYS_CHROOT \
	-v "$SELFDIR/internal:/system:ro" \
	-v "$RUNTIME_DIR/mock:/var/lib/mock" \
	-v "`pwd`:/host" \
	phusion/traveling-ruby-builder \
	/system/my_init --quiet --skip-runit --skip-startup-files -- \
	/bin/bash -l
