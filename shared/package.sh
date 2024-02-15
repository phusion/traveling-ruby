#!/bin/bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/library.sh"
BUNDLER_VERSION=`cat "$SELFDIR/../BUNDLER_VERSION.txt"`
if [[ "$RUBY_VERSIONS" < "3.0.0" ]]; then
    BUNDLER_VERSION="2.4.22"
fi
BUILD_OUTPUT_DIR=
RUBY_PACKAGE=
GEM_NATIVE_EXTENSIONS_DIR=
RUBY_PACKAGE_FULL=

function load_ruby_info()
{
	local BUILD_OUTPUT_DIR="$1"
	RUBY_COMPAT_VERSION=`cat "$BUILD_OUTPUT_DIR/info/RUBY_COMPAT_VERSION"`
	GEM_PLATFORM=`cat "$BUILD_OUTPUT_DIR/info/GEM_PLATFORM"`
	GEM_EXTENSION_API_VERSION=`cat "$BUILD_OUTPUT_DIR/info/GEM_EXTENSION_API_VERSION"`
}

function find_gems_containing_native_extensions()
{
	local BUILD_OUTPUT_DIR="$1"
	(
		shopt -s nullglob
		GEMS=("$BUILD_OUTPUT_DIR"/lib/ruby/gems/$RUBY_COMPAT_VERSION/extensions/$GEM_PLATFORM/$GEM_EXTENSION_API_VERSION/*)
		GEM_NAMES=()
		for GEM in "${GEMS[@]}"; do
			GEM_NAME="`basename \"$GEM\"`"
			GEM_NAMES+=("$GEM_NAME")
		done
		echo "${GEM_NAMES[@]}"
	)
	[[ $? = 0 ]]
}

function usage()
{
	echo "Usage: ./package.sh [options] <BUILD OUTPUT DIR>"
	echo "Package built Traveling Ruby binaries."
	echo
	echo "Options:"
	echo "  -r PATH    Package Ruby into given file"
	echo "  -E DIR     Package gem native extensions into the given directory"
	echo "  -f         Package Ruby with full gem set (not just default gems)"
	echo "  -h         Show this help"
}

function parse_options()
{
	local OPTIND=1
	local opt
	while getopts "r:E:hf" opt; do
		case "$opt" in
		r)
			RUBY_PACKAGE="$OPTARG"
			;;
		f)
			RUBY_PACKAGE_FULL=true
			;;
		E)
			GEM_NATIVE_EXTENSIONS_DIR="$OPTARG"
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
	BUILD_OUTPUT_DIR="$1"

	if [[ "$BUILD_OUTPUT_DIR" = "" ]]; then
		usage
		exit 1
	fi
	if [[ "$RUBY_PACKAGE" = "" && "$GEM_NATIVE_EXTENSIONS_DIR" = "" ]]; then
		echo "ERROR: you must specify either a Ruby package path (-r) or a gem native extensions directory (-E)."
		exit 1
	fi
	if [[ ! -e "$BUILD_OUTPUT_DIR" ]]; then
		echo "ERROR: $BUILD_OUTPUT_DIR doesn't exist."
		exit 1
	fi
}


parse_options "$@"


##########


export GZIP=--best
load_ruby_info "$BUILD_OUTPUT_DIR"

if
	[[ "$RUBY_PACKAGE_FULL" == "true" ]]
then
	header "Packaging Ruby with full gem set and extensions..."
	run tar -cf "$RUBY_PACKAGE.tmp" -C "$BUILD_OUTPUT_DIR" .
	echo "+ gzip --best --no-name -c $RUBY_PACKAGE.tmp > $RUBY_PACKAGE"
	gzip --best --no-name -c "$RUBY_PACKAGE.tmp" > "$RUBY_PACKAGE"
	run rm "$RUBY_PACKAGE.tmp"
	exit 0
elif [[ "$RUBY_PACKAGE" != "" ]]; then
	header "Packaging Ruby..."
	run tar -cf "$RUBY_PACKAGE.tmp" -C "$BUILD_OUTPUT_DIR" \
		--exclude "include/*" \
		--exclude "lib/ruby/gems/$RUBY_COMPAT_VERSION/extensions/*" \
		--exclude "lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*" \
		--exclude "lib/ruby/gems/$RUBY_COMPAT_VERSION/specifications/*" \
		--exclude "lib/ruby/gems/$RUBY_COMPAT_VERSION/deplibs/*" \
		.
	run tar -rf "$RUBY_PACKAGE.tmp" -C "$BUILD_OUTPUT_DIR" \
		"./lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/bundler-$BUNDLER_VERSION" \
		"./lib/ruby/gems/$RUBY_COMPAT_VERSION/specifications/bundler-$BUNDLER_VERSION.gemspec" \
		"./lib/ruby/gems/$RUBY_COMPAT_VERSION/specifications/default"
	echo "+ gzip --best --no-name -c $RUBY_PACKAGE.tmp > $RUBY_PACKAGE"
	gzip --best --no-name -c "$RUBY_PACKAGE.tmp" > "$RUBY_PACKAGE"
	run rm "$RUBY_PACKAGE.tmp"
fi

NATIVE_GEMS=(`find_gems_containing_native_extensions "$BUILD_OUTPUT_DIR"`)


if [[ "$GEM_NATIVE_EXTENSIONS_DIR" != "" ]]; then
	echo
	header "Packaging gem native extensions..."
	if [[ ${#NATIVE_GEMS[@]} -eq 0 ]]; then
		echo "There are no gems with native extensions."
	else
		run mkdir -p "$GEM_NATIVE_EXTENSIONS_DIR"
		for GEM_NAME in "${NATIVE_GEMS[@]}"; do
			GEM_NAME_WITHOUT_VERSION=`echo "$GEM_NAME" | sed -E 's/(.*)-.*/\1/'`
			run tar -cf "$GEM_NATIVE_EXTENSIONS_DIR/$GEM_NAME.tar" \
				-C "$BUILD_OUTPUT_DIR/lib/ruby/gems" \
				"$RUBY_COMPAT_VERSION/extensions/$GEM_PLATFORM/$GEM_EXTENSION_API_VERSION/$GEM_NAME"
			if [[ -e "$BUILD_OUTPUT_DIR/lib/ruby/gems/$RUBY_COMPAT_VERSION/deplibs/$GEM_PLATFORM/$GEM_NAME_WITHOUT_VERSION" ]]; then
				run tar -rf "$GEM_NATIVE_EXTENSIONS_DIR/$GEM_NAME.tar" \
					-C "$BUILD_OUTPUT_DIR/lib/ruby/gems" \
					"$RUBY_COMPAT_VERSION/deplibs/$GEM_PLATFORM/$GEM_NAME_WITHOUT_VERSION"
			fi
			run rm -f "$GEM_NATIVE_EXTENSIONS_DIR/$GEM_NAME.tar.gz"
			run gzip --best --no-name "$GEM_NATIVE_EXTENSIONS_DIR/$GEM_NAME.tar"
		done
	fi
fi
