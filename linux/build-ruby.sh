#!/usr/bin/env bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/../shared/library.sh"

cpucount.sh=`"$SELFDIR/internal/cpucount.sh"`
RUBY_VERSIONS=(`cat "$SELFDIR/../RUBY_VERSIONS.txt"`)

OUTPUT_DIR=
IMAGE=
RUBY_VERSION=${RUBY_VERSIONS[0]}
CACHE_DIR=
CONCURRENCY=$CPUCOUNT
GEMFILE="$SELFDIR/../shared/gemfiles"
DEBUG_SHELL=none
SETUP_SOURCE=true
COMPILE=true
SANITY_CHECK_OUTPUT=true
GEMFILE_MOUNT=()

function usage()
{
	echo "Usage: ./build-ruby.sh [options] <OUTPUT_DIR>"
	echo "Build Traveling Ruby binaries."
	echo
	echo "Options:"
	echo "  -i IMAGE    Docker image to use (e.g. phusion/traveling-ruby-builder-x86_64:1.0)"
	echo "  -r VERSION  Ruby version to build. Default: $RUBY_VERSION"
	echo "  -c DIR      Cache directory to use"
	echo
	echo "  -E          Do not setup source"
	echo "  -C          Do not compile Ruby"
	echo "  -G          Do not install gems"
	echo
	echo "  -j NUMBER   Set build concurrency. Default: $CPUCOUNT"
	echo "  -g PATH     Build gems as specified by the given Gemfile"
	echo "  -d          Open a debugging shell before installing gems"
	echo "  -D          Open a debugging shell after installing gems"
	echo "  -h          Show this help"
}

function parse_options()
{
	local OPTIND=1
	local opt
	while getopts "i:r:c:ECGj:g:dDh" opt; do
		case "$opt" in
		i)
			IMAGE=$OPTARG
			;;
		r)
			RUBY_VERSION=$OPTARG
			;;
		c)
			CACHE_DIR=$OPTARG
			;;
		E)
			SETUP_SOURCE=false
			;;
		C)
			COMPILE=false
			;;
		G)
			GEMFILE=
			;;
		j)
			CONCURRENCY=$OPTARG
			;;
		g)
			GEMFILE="$OPTARG"
			;;
		d)
			DEBUG_SHELL=before
			;;
		D)
			DEBUG_SHELL=after
			;;
		h)
			usage
			exit
			;;
		*)
			return 1
			;;
		esac
	done

	(( OPTIND -= 1 )) || true
	shift $OPTIND || true
	OUTPUT_DIR="$1"

	if [[ "$OUTPUT_DIR" = "" ]]; then
		usage
		exit 1
	fi
	if [[ ! -e "$OUTPUT_DIR" ]]; then
		echo "ERROR: $OUTPUT_DIR doesn't exist."
		exit 1
	fi
	if [[ "$IMAGE" = "" ]]; then
		echo "ERROR: please specify a Docker image with -i."
		exit 1
	fi
	if [[ "$CACHE_DIR" = "" ]]; then
		echo "ERROR: please specify a cache directory with -c."
		exit 1
	fi
	if [[ ! -e "$CACHE_DIR" ]]; then
		echo "ERROR: $CACHE_DIR doesn't exist."
		exit 1
	fi
}


parse_options "$@"
OUTPUT_DIR=`cd "$OUTPUT_DIR" && pwd`
CACHE_DIR=`cd "$CACHE_DIR" && pwd`
if [[ "$GEMFILE" != "" ]]; then
	GEMFILE="`absolute_path \"$GEMFILE\"`"
	if [[ -d "$GEMFILE" ]]; then
		for F in "$GEMFILE"/*/Gemfile; do
			DIR="`dirname \"$F\"`"
			DIR="`basename \"$DIR\"`"
			GEMFILE_MOUNT+=(-v "$F:/gemfiles/$DIR/Gemfile:ro")
			if [[ -e "$F.lock" ]]; then
				GEMFILE_MOUNT+=(-v "$F.lock:/gemfiles/$DIR/Gemfile.lock:ro")
			fi
		done
	else
		GEMFILE_MOUNT=(-v "$GEMFILE:/gemfiles/default/Gemfile:ro")
		if [[ -e "$GEMFILE.lock" ]]; then
			GEMFILE_MOUNT+=(-v "$GEMFILE.lock:/gemfiles/default/Gemfile.lock:ro")
		fi
	fi
fi
if [[ "$DEBUG_SHELL" = none ]]; then
	if tty -s; then
		TTY_ARGS=(-ti)
	else
		TTY_ARGS=()
	fi
else
	TTY_ARGS=(-ti)
fi

exec docker run \
	"${TTY_ARGS[@]}" \
	--rm \
	--init \
	-v "$SELFDIR/internal:/system:ro" \
	-v "$SELFDIR/../shared:/system_shared:ro" \
	-v "$OUTPUT_DIR:/output" \
	-v "$CACHE_DIR:/cache" \
	"${GEMFILE_MOUNT[@]}" \
	-e "APP_UID=`id -u`" \
	-e "APP_GID=`id -g`" \
	-e "BUNDLER_VERSION=`cat \"$SELFDIR/../BUNDLER_VERSION.txt\"`" \
	-e "ARCHITECTURE=$ARCHITECTURE" \
	-e "RUBY_VERSION=$RUBY_VERSION" \
	-e "CONCURRENCY=$CONCURRENCY" \
	-e "SETUP_SOURCE=$SETUP_SOURCE" \
	-e "COMPILE=$COMPILE" \
	-e "SANITY_CHECK_OUTPUT=$SANITY_CHECK_OUTPUT" \
	-e "DEBUG_SHELL=$DEBUG_SHELL" \
	"$IMAGE" \
	/system/build-ruby.sh
