#!/bin/bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/internal/reset_environment.sh"
source "$SELFDIR/../shared/library.sh"
BUNDLER_VERSION=`cat "$SELFDIR/../BUNDLER_VERSION.txt"`
RUBY_VERSIONS=(`cat "$SELFDIR/../RUBY_VERSIONS.txt"`)
RUBYGEMS_VERSION=`cat "$SELFDIR/../RUBYGEMS_VERSION.txt"`

GEMFILES=()

RUNTIME_DIR=
OUTPUT_DIR=
ARCHITECTURE=$(uname -m)
RUBY_VERSION=${RUBY_VERSIONS[0]}
WORKDIR=
OWNS_WORKDIR=true
CONCURRENCY=$(sysctl -n hw.ncpu)
GEMFILE="$SELFDIR/../shared/gemfiles"
SETUP_SOURCE=true
COMPILE=true

function _cleanup()
{
	if $OWNS_WORKDIR && [[ "$WORKDIR" != "" ]]; then
		echo "Removing working directory $WORKDIR"
		rm -rf "$WORKDIR"
	fi
}

function create_environment_file() {
	local FILE="$1"
	local LOAD_PATHS

	LOAD_PATHS=`"$TMPBUILDROOT/bin.real/ruby" "$SELFDIR/../shared/dump-load-paths.rb" "$TMPBUILDROOT"`

	cat > "$FILE" <<'EOF'
#!/bin/bash
ROOT=`dirname "$0"`
ROOT=`cd "$ROOT/.." && pwd`

echo ORIG_TERMINFO=\"$TERMINFO\"
echo ORIG_SSL_CERT_DIR=\"$SSL_CERT_DIR\"
echo ORIG_SSL_CERT_FILE=\"$SSL_CERT_FILE\"
echo ORIG_RUBYOPT=\"$RUBYOPT\"
echo ORIG_RUBYLIB=\"$RUBYLIB\"

echo TERMINFO=/usr/share/terminfo
echo SSL_CERT_FILE=\"$ROOT/lib/ca-bundle.crt\"
echo RUBYOPT=\"-rtraveling_ruby_restore_environment\"
EOF
	echo "echo GEM_HOME=\\\"\$ROOT/lib/ruby/gems/$RUBY_COMPAT_VERSION\\\"" >> "$FILE"
	echo "echo GEM_PATH=\\\"\$ROOT/lib/ruby/gems/$RUBY_COMPAT_VERSION\\\"" >> "$FILE"

	cat >> "$FILE" <<EOF
echo RUBYLIB=\"$LOAD_PATHS\"

echo export ORIG_TERMINFO
echo export ORIG_SSL_CERT_DIR
echo export ORIG_SSL_CERT_FILE
echo export ORIG_RUBYOPT
echo export ORIG_RUBYLIB

echo export TERMINFO
echo unset  SSL_CERT_DIR
echo export SSL_CERT_FILE
echo export RUBYOPT
echo export GEM_HOME
echo export GEM_PATH
echo export RUBYLIB
EOF

	chmod +x "$FILE"
}

function create_wrapper()
{
	local FILE="$1"
	local NAME="$2"
	local IS_RUBY_SCRIPT="$3"

	cat > "$FILE" <<'EOF'
#!/bin/bash
set -e
ROOT=`dirname "$0"`
ROOT=`cd "$ROOT/.." && pwd`
eval "`\"$ROOT/bin/ruby_environment\"`"
EOF
	if $IS_RUBY_SCRIPT; then
		cat >> "$FILE" <<EOF
exec "\$ROOT/bin.real/ruby" "\$ROOT/bin.real/$NAME" "\$@"
EOF
	else
		cat >> "$FILE" <<EOF
exec "\$ROOT/bin.real/$NAME" "\$@"
EOF
	fi
	chmod +x "$FILE"
}

function debug_shell()
{
	(
		cd "$TMPBUILDROOT"
		export PATH="$TMPBUILDROOT/bin:$PATH"
		echo "Debug shell:"
		sh
	)
	[[ $? == 0 ]]
}

function usage()
{
	echo "Usage: ./build-ruby.sh [options] <RUNTIME DIR> <OUTPUT DIR>"
	echo "Build Traveling Ruby binaries."
	echo
	echo "Options:"
	echo "  -a NAME        Architecture to setup (e.g. x86_64 or arm64)"
	echo "  -E          Do not setup source"
	echo "  -C          Do not compile Ruby"
	echo "  -G          Do not install gems"
	echo
	echo "  -r VERSION  Ruby version to build. Default: $RUBY_VERSION"
	echo "  -w DIR      Use the given working directory instead of creating a temporary one"
	echo "  -j NUM      Compilation concurrency. Default: 4"
	echo "  -g PATH     Build gems as specified by the given Gemfile"
	echo "  -h          Show this help"
}

function parse_options()
{
	local OPTIND=1
	local opt
	while getopts "a:ECGr:w:j:g:h" opt; do
		case "$opt" in
		a)
			ARCHITECTURE=$OPTARG
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
		r)
			RUBY_VERSION=$OPTARG
			;;
		w)
			WORKDIR="$OPTARG"
			OWNS_WORKDIR=false
			;;
		j)
			CONCURRENCY=$OPTARG
			;;
		g)
			GEMFILE="$OPTARG"
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
	RUNTIME_DIR="$1"
	OUTPUT_DIR="$2"

	if [[ "$RUNTIME_DIR" = "" || "$OUTPUT_DIR" = "" ]]; then
		usage
		exit 1
	fi
	if [[ ! -e "$RUNTIME_DIR" ]]; then
		echo "ERROR: $RUNTIME_DIR doesn't exist."
		exit 1
	fi
	if [[ ! -e "$OUTPUT_DIR" ]]; then
		echo "ERROR: $OUTPUT_DIR doesn't exist."
		exit 1
	fi
}

parse_options "$@"
RUNTIME_DIR="`cd \"$RUNTIME_DIR\" && pwd`"
OUTPUT_DIR="`cd \"$OUTPUT_DIR\" && pwd`"
if [[ "$WORKDIR" = "" ]]; then
	WORKDIR=`mktemp -d /tmp/traveling-ruby.XXXXXXXX`
elif [[ ! -e "$WORKDIR" ]]; then
	echo "ERROR: working directory $WORKDIR doesn't exist."
	exit 1
else
	WORKDIR="`cd \"$WORKDIR\" && pwd`"
fi
TMPBUILDROOT="$WORKDIR/inst"
if [[ "$GEMFILE" != "" ]]; then
	GEMFILE="`absolute_path \"$GEMFILE\"`"
	if [[ -d "$GEMFILE" ]]; then
		GEMFILES=("$GEMFILE"/*/Gemfile)
	else
		GEMFILES=("$GEMFILE")
	fi
fi
if [[ -e ~/.bundle/config ]]; then
	echo "ERROR: ~/.bundle/config detected. Global Bundler configuration" \
		"could conflict with this build script, so please remove" \
		"~/.bundle/config first."
	exit 1
fi
"$SELFDIR/internal/check_requirements.sh"
if [[ "$ARCHITECTURE" == "x86_64" ]]; then
	BUILD_TARGET="darwin64-x86_64-cc"
	DEPLOY_TARGET="x86_64-apple-darwin22"
elif [[ "$ARCHITECTURE" == "arm64" ]]; then
	BUILD_TARGET="darwin64-arm64-cc"
	DEPLOY_TARGET="aarch64-apple-darwin22"
else
	echo "*** ERROR: unknown architecture $ARCHITECTURE, don't know how to build"
	echo "set ARCHITECTURE to one of: x86_64 arm64"
	echo "we detected you are running on via uname: $(uname -m)"
	exit 1
fi

#######################################
RUBY_MAJOR=`echo $RUBY_VERSION | cut -d . -f 1`
RUBY_MINOR=`echo $RUBY_VERSION | cut -d . -f 2`
RUBY_PATCH=`echo $RUBY_VERSION | cut -d . -f 3 | cut -d - -f 1`
RUBY_PREVIEW=`echo $RUBY_VERSION | grep -e '-' | cut -d - -f 2`
RUBY_MAJOR_MINOR="$RUBY_MAJOR.$RUBY_MINOR"
echo "RUBY_MAJOR=$RUBY_MAJOR"
echo "RUBY_MINOR=$RUBY_MINOR"
echo "RUBY_PATCH=$RUBY_PATCH"
echo "RUBY_PREVIEW=$RUBY_PREVIEW"
echo "RUBY_MAJOR_MINOR=$RUBY_MAJOR_MINOR"

if [[ ! -e "$RUNTIME_DIR/ruby-$RUBY_VERSION.tar.gz" ]]; then
	header "Downloading Ruby source code..."
	run rm -f "$RUNTIME_DIR/ruby-$RUBY_VERSION.tar.gz.tmp"
	run curl --fail -L -o "$RUNTIME_DIR/ruby-$RUBY_VERSION.tar.gz.tmp" \
		http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR_MINOR/ruby-$RUBY_VERSION.tar.gz
	run mv "$RUNTIME_DIR/ruby-$RUBY_VERSION.tar.gz.tmp" "$RUNTIME_DIR/ruby-$RUBY_VERSION.tar.gz"
	echo
fi


header "Preparing Ruby source code..."

# To many warnings, suppress them all (disable in case of troubleshooting)
# export CPPFLAGS="-w"
# export CXXFLAGS="-w"
# export CFLAGS="-w"

export PATH="$RUNTIME_DIR/bin:$PATH"
export LIBRARY_PATH="$RUNTIME_DIR/lib"
export PKG_CONFIG_PATH="$RUNTIME_DIR/lib/pkgconfig:/usr/lib/pkgconfig"
export CCACHE_DIR="$RUNTIME_DIR/ccache"
export CCACHE_COMPRESS=1
export CCACHE_COMPRESS_LEVEL=3
export RUNTIME_DIR
export TMPBUILDROOT
export DEAD_STRIP=false
export RUBYOPT=-r"$SELFDIR/internal/modify_rbconfig_while_building"

echo "Entering working directory $WORKDIR"
pushd "$WORKDIR" >/dev/null

if $SETUP_SOURCE; then
	run rm -rf "ruby-$RUBY_VERSION"
	run tar xzf "$RUNTIME_DIR/ruby-$RUBY_VERSION.tar.gz"
fi
echo "Entering ruby-$RUBY_VERSION"
pushd "ruby-$RUBY_VERSION" >/dev/null
echo


if $SETUP_SOURCE; then
	header "Configuring..."
	./configure \
		--prefix "$TMPBUILDROOT" \
		--with-out-ext=tk,sdbm,gdbm,dbm,dl,coverage \
		--disable-install-doc \
		--with-openssl-dir="$RUNTIME_DIR" \
		--build=$DEPLOY_TARGET
	echo
fi


if $COMPILE; then
	header "Compiling..."
	run make -j$CONCURRENCY Q= V=1 exts.mk
	run make -j$CONCURRENCY Q= V=1
	echo
fi


header "Installing to temporary build output directory..."
(
	shopt -s dotglob
	run mkdir -p "$TMPBUILDROOT"
	run rm -rf "$TMPBUILDROOT"/*
)
[[ $? == 0 ]]
run make install-nodoc
echo


header "Postprocessing build output..."

echo "Entering $TMPBUILDROOT"
pushd "$TMPBUILDROOT" >/dev/null

# Copy over various useful files.
run cp -pR "$RUNTIME_DIR"/lib/*.dylib* lib/
run cp "$SELFDIR/internal/traveling_ruby_restore_environment.rb" lib/ruby/site_ruby/
run cp "$SELFDIR/../shared/ca-bundle.crt" lib/
export SSL_CERT_FILE="$TMPBUILDROOT/lib/ca-bundle.crt"

# Dump various information about the Ruby binaries.
RUBY_COMPAT_VERSION=`"$TMPBUILDROOT/bin/ruby" -rrbconfig -e 'puts RbConfig::CONFIG["ruby_version"]'`
RUBY_ARCH=`"$TMPBUILDROOT/bin/ruby" -rrbconfig -e 'puts RbConfig::CONFIG["arch"]'`
GEM_PLATFORM=`"$TMPBUILDROOT/bin/ruby" -e 'puts Gem::Platform.local.to_s'`
GEM_EXTENSION_API_VERSION=`"$TMPBUILDROOT/bin/ruby" -e 'puts Gem.extension_api_version'`
run mkdir info
echo "Dumping information about the Ruby binaries into $TMPBUILDROOT/info"
echo $RUBY_COMPAT_VERSION > info/RUBY_COMPAT_VERSION
echo $RUBYARCH > info/RUBY_ARCH
echo $GEM_PLATFORM > info/GEM_PLATFORM
echo $GEM_EXTENSION_API_VERSION > info/GEM_EXTENSION_API_VERSION
echo "RUBY_COMPAT_VERSION is $RUBY_COMPAT_VERSION"
echo "RUBY_ARCH is $RUBY_ARCH"
echo "GEM_PLATFORM is $GEM_PLATFORM"
echo "GEM_EXTENSION_API_VERSION is $GEM_EXTENSION_API_VERSION"
echo "Patching rbconfig.rb"
echo >> "$TMPBUILDROOT/lib/ruby/$RUBY_COMPAT_VERSION/$RUBY_ARCH/rbconfig.rb"
cat "$SELFDIR/internal/rbconfig_patch.rb" >> "$TMPBUILDROOT/lib/ruby/$RUBY_COMPAT_VERSION/$RUBY_ARCH/rbconfig.rb"

# Remove some standard dummy gems. We must do this before
# installing further gems in order to prevent accidentally
# removing explicitly gems.
run rm -rf lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/{test-unit,rdoc}-*

if [[ "$GEMFILE" != "" ]]; then
	# Restore cached gems.
	if [[ -e "$RUNTIME_DIR/vendor" ]]; then
		run cp -pR "$RUNTIME_DIR/vendor" vendor
	fi

	# Update RubyGems to the specified version.
	
	

	header "Updating RubyGems..."

	if "$TMPBUILDROOT/bin/gem" --version | grep -q $RUBYGEMS_VERSION; then
		echo "RubyGems is up to date."
	else
		echo "RubyGems is out of date, updating..."
		run "$TMPBUILDROOT/bin/gem" update --system $RUBYGEMS_VERSION --no-document
		run "$TMPBUILDROOT/bin/gem" uninstall -x rubygems-update
	fi

	# Install Bundler, either from cache or directly.
	if [[ -e "$RUNTIME_DIR/vendor/cache/bundler-$BUNDLER_VERSION.gem" ]]; then
		run "$TMPBUILDROOT/bin/gem" install "$RUNTIME_DIR/vendor/cache/bundler-$BUNDLER_VERSION.gem" --no-document
	else
		run "$TMPBUILDROOT/bin/gem" install bundler -v $BUNDLER_VERSION --no-document
		run mkdir -p "$RUNTIME_DIR/vendor/cache"
		run cp "$TMPBUILDROOT"/lib/ruby/gems/$RUBY_COMPAT_VERSION/cache/bundler-$BUNDLER_VERSION.gem \
			"$RUNTIME_DIR/vendor/cache/"
	fi

	export BUNDLE_BUILD__NOKOGIRI="--with-xml2-include=$RUNTIME_DIR/include/libxml2"
	export BUNDLE_BUILD__FFI="--use-system-libraries"
	export BUNDLE_BUILD__MYSQL2="--with-mysql_config"
	export BUNDLE_BUILD__CHARLOCK_HOLMES="--with-icu-dir=$RUNTIME_DIR"

	# Run bundle install.
	for GEMFILE in "${GEMFILES[@]}"; do
		run cp "$GEMFILE" ./
		if [[ -e "$GEMFILE.lock" ]]; then
			run cp "$GEMFILE.lock" ./
		fi
		# run bundle config --local force_ruby_platform true
		run "$TMPBUILDROOT/bin/bundle" config set --local system true
		run "$TMPBUILDROOT/bin/bundle" install --retry 3 --jobs $CONCURRENCY
		run "$TMPBUILDROOT/bin/bundle" package

		# Cache gems.
		run mkdir -p "$RUNTIME_DIR/vendor/cache"
		run mv vendor/cache/* "$RUNTIME_DIR"/vendor/cache/

		run rm -rf Gemfile* .bundle
	done
fi

# Strip binaries and remove unnecessary files.
run strip -S bin/ruby
echo "Stripping libraries..."
find . -name '*.bundle'
find . -name '*.dylib'
(
	set -o pipefail
	find . -name '*.bundle' | xargs strip -S
	find . -name '*.dylib' | xargs strip -S
)
[[ $? == 0 ]]
run rm bin/{erb,rdoc,ri}
run rm -f bin/testrb # Only Ruby 2.1 has it
run rm -rf include
run rm -rf share
run rm -rf lib/{libruby*static.a,pkgconfig}
# NOTE:- Updated the above to consider the below library, otherwise
# the size of our bundle doubles
# 	find output -type f -exec du -ah {} + | sort -rh | head -n 10
#  21M    output/3.2.2-arm64/lib/libruby.3.2-static.a

# run rm -rf lib/ruby/$RUBY_COMPAT_VERSION/rdoc/generator/
run rm -rf lib/ruby/gems/$RUBY_COMPAT_VERSION/cache/*
run rm -f lib/ruby/gems/$RUBY_COMPAT_VERSION/extensions/$GEM_PLATFORM/$GEM_EXTENSION_API_VERSION/*/{gem_make.out,mkmf.log}
run rm -rf lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/{test,spec,*.md,*.rdoc}
run rm -rf lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/ext/*/*.{c,h,Makefile}

# removes rugged libgit2 vendor folder
find lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/vendor | xargs rm -rf
# run rm -rf lib/ruby/$RUBY_COMPAT_VERSION/rdoc/generator/
run rm -rf lib/ruby/gems/$RUBY_COMPAT_VERSION/cache/*
run rm -f lib/ruby/gems/$RUBY_COMPAT_VERSION/extensions/$GEM_PLATFORM/$GEM_EXTENSION_API_VERSION/*/{gem_make.out}
run rm -rf lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/{test,spec,*.md,*.rdoc}
run rm -rf lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/ext/*/*.{c,h}
# removes rugged libgit2 vendor folder
find lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/vendor | xargs rm -rf
find lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/* -path '*/ports/*' | xargs rm -rf
find lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/* -name '*.bundle' | xargs rm -rf
find lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/ext/*/tmp | xargs rm -rf
find lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/contrib | xargs rm -rf
find lib -type f -name '*.java'| xargs rm -f
find lib -type f -name '*.class'| xargs rm -f
find . -name '.travis.yml'| xargs rm -rf
find . -name '.github'| xargs rm -rf

# Remove absolute rpaths to the runtime
echo "Removing absolute rpaths to the runtime..."
(
	set -o pipefail
	BINARIES=$(find . -name '*.bundle' && find . -name '*.dylib')
	BINARIES="bin/ruby $BINARIES"
	for BINARY in $BINARIES; do
		RPATHS=$(otool -l "$BINARY" | (grep LC_RPATH -A2 || true) | (grep ' path ' || true) | awk '{ print $2 }')
		if grep -qF "$RUNTIME_DIR/lib" <<<"$RPATHS"; then
			run install_name_tool -delete_rpath "$RUNTIME_DIR/lib" "$BINARY"
		fi
	done
)
[[ $? == 0 ]]

if [[ "$GEMFILE" != "" ]]; then
	echo "Entering Bundler gem directory"
	pushd lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/bundler-$BUNDLER_VERSION >/dev/null
	rm -rf .gitignore .rspec .travis.yml man Rakefile lib/bundler/man/*.txt lib/bundler/templates .github .git
	popd >/dev/null
	echo "Leaving Bundler gem directory"
fi

# Create wrapper scripts.
run mv bin bin.real
run mkdir bin
run create_environment_file bin/ruby_environment

run create_wrapper bin/ruby ruby false
run create_wrapper bin/gem gem true
run create_wrapper bin/irb irb true
run create_wrapper bin/rake rake true
if $INSTALL_GEMS; then
	run create_wrapper bin/bundle bundle true
	run create_wrapper bin/bundler bundler true
fi

echo "Leaving $TMPBUILDROOT"
popd >/dev/null
echo


header "Sanity checking build output..."
bash "$SELFDIR/internal/sanity_check.sh" "$TMPBUILDROOT"
echo


header "Committing build output..."
shopt -s dotglob
run rm -rf "$OUTPUT_DIR"/*
run mv "$TMPBUILDROOT"/* "$OUTPUT_DIR"/
echo

header "All done!"
