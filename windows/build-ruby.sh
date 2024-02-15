#!/bin/bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/../shared/library.sh"

BUNDLER_VERSION=`cat "$SELFDIR/../BUNDLER_VERSION.txt"`
RUBY_VERSIONS=(`cat "$SELFDIR/../RUBY_VERSIONS.txt"`)
RUBYGEMS_VERSION=`cat "$SELFDIR/../RUBYGEMS_VERSION.txt"`
N_RUBY_VERSIONS=${#RUBY_VERSIONS[@]}
LAST_RUBY_VERSION_INDEX=$((N_RUBY_VERSIONS - 1))

CACHE_DIR=
OUTPUT_DIR=
ARCHITECTURE=x86_64
RUBY_VERSION=${RUBY_VERSIONS[$LAST_RUBY_VERSION_INDEX]}
if [[ "$RUBY_VERSION" < "3.0" ]]; then
    BUNDLER_VERSION="2.4.22"
fi
RELEASE_NUM=1

function usage()
{
	echo "Usage: ./build-ruby.sh [options] <CACHE DIR> <OUTPUT DIR>"
	echo "Build Ruby binaries."
	echo
	echo "Options:"
	echo "  -a NAME        Architecture to setup (e.g. x86_64)"
	echo "  -r VERSION     Ruby version to build. Default: $RUBY_VERSION"
	echo "  -e RELEASENUM  RubyInstaller release number. Default: $RELEASE_NUM"
	echo "  -h             Show this help"
}

function parse_options()
{
	local OPTIND=1
	local opt
	while getopts "a:r:e:h" opt; do
		case "$opt" in
		a)
			ARCHITECTURE=$OPTARG
			;;
		r)
			RUBY_VERSION=$OPTARG
			;;
		e)
			RELEASE_NUM=$OPTARG
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
	CACHE_DIR="$1"
	OUTPUT_DIR="$2"

	if [[ "$CACHE_DIR" = "" || "$OUTPUT_DIR" = "" ]]; then
		usage
		exit 1
	fi
	if [[ ! -e "$CACHE_DIR" ]]; then
		echo "ERROR: $CACHE_DIR doesn't exist."
		exit 1
	fi
	if [[ ! -e "$OUTPUT_DIR" ]]; then
		echo "ERROR: $OUTPUT_DIR doesn't exist."
		exit 1
	fi
}

function create_wrapper()
{
	local FILE="$1"
	local NAME="$2"
	local IS_RUBY_SCRIPT="$3"

	cat > "$FILE" <<EOF
@ECHO OFF
IF NOT "%~f0" == "~f0" GOTO :WinNT
ECHO.This version of Ruby has not been built with support for Windows 95/98/Me.
GOTO :EOF
:WinNT

set RUBY_COMPAT_VERSION=$RUBY_COMPAT_VERSION
set RUBY_ARCH=$RUBY_ARCH

set RUBYLIB=%~dp0..\\lib\\ruby\\site_ruby\\%RUBY_COMPAT_VERSION%
set RUBYLIB=%RUBYLIB%;%~dp0..\\lib\\ruby\\site_ruby\\%RUBY_COMPAT_VERSION%\\%RUBY_ARCH%
set RUBYLIB=%RUBYLIB%;%~dp0..\\lib\\ruby\\site_ruby
set RUBYLIB=%RUBYLIB%;%~dp0..\\lib\\ruby\\vendor_ruby\\%RUBY_COMPAT_VERSION%
set RUBYLIB=%RUBYLIB%;%~dp0..\\lib\\ruby\\vendor_ruby\\%RUBY_COMPAT_VERSION%\\%RUBY_ARCH%
set RUBYLIB=%RUBYLIB%;%~dp0..\\lib\\ruby\\vendor_ruby
set RUBYLIB=%RUBYLIB%;%~dp0..\\lib\\ruby\\%RUBY_COMPAT_VERSION%
set RUBYLIB=%RUBYLIB%;%~dp0..\\lib\\ruby\\%RUBY_COMPAT_VERSION%\\%RUBY_ARCH%
set RUBY_COMPAT_VERSION=
set RUBY_ARCH=

set SSL_CERT_DIR=
set SSL_CERT_FILE=%~dp0..\\lib\\ca-bundle.crt
EOF
	if $IS_RUBY_SCRIPT; then
		cat >> "$FILE" <<EOF
@"%~dp0..\\bin.real\\ruby.exe" "%~dp0..\\bin.real\\$NAME" %*
EOF
	else
		cat >> "$FILE" <<EOF
@"%~dp0..\\bin.real\\$NAME.exe" %*
EOF
	fi
}


parse_options "$@"
CACHE_DIR=`cd "$CACHE_DIR" && pwd`
OUTPUT_DIR=`cd "$OUTPUT_DIR" && pwd`


########


if [[ "$ARCHITECTURE" = "x86_64" ]]; then
	RUBY_FILE_ARCH=x64
else
	RUBY_FILE_ARCH="$ARCHITECTURE"
fi
RUBY_FILE="rubyinstaller-$RUBY_VERSION-$RELEASE_NUM-$RUBY_FILE_ARCH.7z"
RUBY_URL="https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-$RUBY_VERSION-$RELEASE_NUM/$RUBY_FILE"


header "Downloading Ruby..."
if ! [[ -e "$CACHE_DIR/$RUBY_FILE" ]]; then
	run rm -f "$CACHE_DIR/$RUBY_FILE.tmp"
	run curl --fail -L -o "$CACHE_DIR/$RUBY_FILE.tmp" "$RUBY_URL"
	run mv "$CACHE_DIR/$RUBY_FILE.tmp" "$CACHE_DIR/$RUBY_FILE"
else
	echo "Already downloaded."
fi
echo


header "Extracting Ruby..."
(
	shopt -s dotglob
	run rm -rf "$OUTPUT_DIR"/*
	echo "+ In $OUTPUT_DIR:"
	cd "$OUTPUT_DIR"
	echo "+ 7z x $CACHE_DIR/$RUBY_FILE"
	if command -v 7z >/dev/null 2>&1; then
		7z x "$CACHE_DIR/$RUBY_FILE" >/dev/null
	else
		echo "no 7z found, trying 7zz"
		echo "tip: on mac brew install 7zip"
		7zz x "$CACHE_DIR/$RUBY_FILE" >/dev/null
	fi
)
if [[ $? != 0 ]]; then
	exit 1
fi
run mv "$OUTPUT_DIR/rubyinstaller-$RUBY_VERSION-$RELEASE_NUM-$RUBY_FILE_ARCH"/* "$OUTPUT_DIR/"
run rm -rf "$OUTPUT_DIR/rubyinstaller-$RUBY_VERSION-$RELEASE_NUM-$RUBY_FILE_ARCH"
echo


header "Analyzing Ruby..."
if [[ "$OS" =~ Windows ]]; then
	export PATH="$OUTPUT_DIR/bin:$PATH"
fi
RUBY_COMPAT_VERSION=`grep '"ruby_version"' "$OUTPUT_DIR"/lib/ruby/*/*/rbconfig.rb | sed -E 's/.*=//; s/.*"(.*)".*/\1/'`
RUBY_ARCH=`grep '"arch"' "$OUTPUT_DIR"/lib/ruby/*/*/rbconfig.rb | sed -E 's/.*=//; s/.*"(.*)".*/\1/'`
GEM_PLATFORM=`ruby -rrubygems -e "puts Gem::Platform.new('$RUBY_ARCH').to_s"`
GEM_EXTENSION_API_VERSION=$RUBY_COMPAT_VERSION
run mkdir "$OUTPUT_DIR/info"
echo "+ Dumping information about the Ruby binaries into /tmp/ruby/info"
echo $RUBY_COMPAT_VERSION > "$OUTPUT_DIR/info/RUBY_COMPAT_VERSION"
echo $RUBY_ARCH > "$OUTPUT_DIR/info/RUBY_ARCH"
echo $GEM_PLATFORM > "$OUTPUT_DIR/info/GEM_PLATFORM"
echo $GEM_EXTENSION_API_VERSION > "$OUTPUT_DIR/info/GEM_EXTENSION_API_VERSION"
echo

header "Updating RubyGems..."

if $OUTPUT_DIR/bin/gem --version | grep -q $RUBYGEMS_VERSION; then
	echo "RubyGems is up to date."
else
	echo "RubyGems is out of date, updating..."
	run $OUTPUT_DIR/bin/gem update --system $RUBYGEMS_VERSION --no-document
fi

header "Installing Bundler..."
if [[ -e "$CACHE_DIR/bundler-$BUNDLER_VERSION.gem" ]]; then
	run $OUTPUT_DIR/bin/gem install "$CACHE_DIR/bundler-$BUNDLER_VERSION.gem" --no-document \
		--install-dir "$OUTPUT_DIR/lib/ruby/gems/$RUBY_COMPAT_VERSION"
else
	run $OUTPUT_DIR/bin/gem install bundler -v $BUNDLER_VERSION --no-document \
		--install-dir "$OUTPUT_DIR/lib/ruby/gems/$RUBY_COMPAT_VERSION"
fi
run cp "$OUTPUT_DIR/lib/ruby/gems/$RUBY_COMPAT_VERSION/cache"/*.gem "$CACHE_DIR/" || true
echo


header "Postprocessing..."
echo "+ Entering $OUTPUT_DIR"
pushd "$OUTPUT_DIR"

run cp "$SELFDIR/../shared/ca-bundle.crt" lib/

run rm bin/{erb,rdoc,ri}*
run rm -rf include
run rm -rf share
run rm -f lib/*.a
run rm -rf lib/pkgconfig
run rm -rf lib/tcltk
run rm -rf lib/ruby/$RUBY_COMPAT_VERSION/{tcltk,tk,sdbm,gdbm,dbm,dl,coverage}
run rm -rf lib/ruby/$RUBY_COMPAT_VERSION/{tk,sdbm,gdbm,dbm,dl,coverage}.rb
run rm -rf lib/ruby/$RUBY_COMPAT_VERSION/tk*
# run rm -rf lib/ruby/$RUBY_COMPAT_VERSION/rdoc/generator/
run rm -f lib/ruby/gems/$RUBY_COMPAT_VERSION/cache/*
run rm -f /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/extensions/$GEM_PLATFORM/$GEM_EXTENSION_API_VERSION/*/{gem_make.out,mkmf.log}
run rm -rf lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/{test,spec,*.md,*.rdoc}
run rm -rf lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/ext/*/*.{c,h}

echo "+ Entering Bundler gem directory"
pushd lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/bundler-$BUNDLER_VERSION >/dev/null
rm -rf .gitignore .rspec .travis.yml man Rakefile lib/bundler/man/*.txt lib/bundler/templates
popd >/dev/null
echo "+ Leaving Bundler gem directory"

# Create wrapper scripts.
run mv bin bin.real
run mkdir bin
run create_wrapper bin/ruby.bat ruby false
run create_wrapper bin/gem.bat gem true
run create_wrapper bin/irb.bat irb true
run create_wrapper bin/rake.bat rake true
run create_wrapper bin/bundle.bat bundle true
run create_wrapper bin/bundler.bat bundler true

echo "+ Leaving $OUTPUT_DIR"
popd >/dev/null
echo

header "All done!"
