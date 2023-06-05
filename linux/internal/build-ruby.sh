#!/usr/bin/env bash
set -e

# shellcheck source=shared/library.sh
source /system_shared/library.sh

function grep_without_fail()
{
	grep "$@" || true
}

function create_environment_file() {
	local FILE="$1"
	local LOAD_PATHS

	LOAD_PATHS=`/tmp/ruby/bin.real/ruby /system_shared/dump-load-paths.rb`

	cat > "$FILE" <<'EOF'
#!/usr/bin/env bash
ROOT=`dirname "$0"`
ROOT=`cd "$ROOT/.." && pwd`

echo ORIG_LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH\"
echo ORIG_SSL_CERT_DIR=\"$SSL_CERT_DIR\"
echo ORIG_SSL_CERT_FILE=\"$SSL_CERT_FILE\"
echo ORIG_RUBYOPT=\"$RUBYOPT\"
echo ORIG_RUBYLIB=\"$RUBYLIB\"

echo LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH:$ROOT/lib\"
echo SSL_CERT_FILE=\"$ROOT/lib/ca-bundle.crt\"
echo RUBYOPT=\"-rtraveling_ruby_restore_environment\"
for DIR in "$ROOT"/lib/ruby/gems/*/deplibs/*/*; do
	echo LD_LIBRARY_PATH=\"\$LD_LIBRARY_PATH:$DIR\"
done
EOF
	echo "echo GEM_HOME=\\\"\$ROOT/lib/ruby/gems/$RUBY_COMPAT_VERSION\\\"" >> "$FILE"
	echo "echo GEM_PATH=\\\"\$ROOT/lib/ruby/gems/$RUBY_COMPAT_VERSION\\\"" >> "$FILE"

	cat >> "$FILE" <<EOF
echo RUBYLIB=\"$LOAD_PATHS\"

echo export ORIG_LD_LIBRARY_PATH
echo export ORIG_SSL_CERT_DIR
echo export ORIG_SSL_CERT_FILE
echo export ORIG_RUBYOPT
echo export ORIG_RUBYLIB

echo export LD_LIBRARY_PATH
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
#!/usr/bin/env bash
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

cd /tmp
echo


# shellcheck disable=SC1091
source /hbb_shlib/activate
# -fvisibility=hidden interferes with native extension compilation
export CFLAGS="${CFLAGS//-fvisibility=hidden/}"
export CXXFLAGS="${CXXFLAGS//-fvisibility=hidden/}"

if [[ ! -e /ruby-$RUBY_VERSION.tar.gz ]]; then
	header "Downloading Ruby source"
	RUBY_MAJOR=`echo $RUBY_VERSION | cut -d . -f 1`
	RUBY_MINOR=`echo $RUBY_VERSION | cut -d . -f 2`
	RUBY_MAJOR_MINOR="$RUBY_MAJOR.$RUBY_MINOR"
	run rm -f /ruby-$RUBY_VERSION.tar.gz.tmp
	run wget -O /ruby-$RUBY_VERSION.tar.gz.tmp \
		http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR_MINOR/ruby-$RUBY_VERSION.tar.gz
	run mv /ruby-$RUBY_VERSION.tar.gz.tmp /ruby-$RUBY_VERSION.tar.gz
	echo
fi

if $SETUP_SOURCE; then
	header "Extracting source code"
	run rm -rf /tmp/ruby-$RUBY_VERSION
	run tar xzf /ruby-$RUBY_VERSION.tar.gz
	echo "Entering ruby-$RUBY_VERSION"
	cd ruby-$RUBY_VERSION
	echo

	header "Configuring"
	run ./configure \
		--prefix /tmp/ruby \
		--disable-install-doc \
		--with-out-ext=tk,sdbm,gdbm,dbm,dl,coverage
	echo
else
	echo "Entering ruby-$RUBY_VERSION"
	cd ruby-$RUBY_VERSION
	echo
fi


if $COMPILE; then
	header "Compiling"
	run sed -i 's|dir_config("openssl")|$libs << " -lz "; dir_config("openssl")|' ext/openssl/extconf.rb
	# Do not link to ncurses. We want it to link to libtermcap instead, which is much smaller.
	if [[ $RUBY_MAJOR -lt 3 || $RUBY_MAJOR -eq 3 && $RUBY_MINOR -lt 3 ]]; then
		echo overwriting ext/readline/extconf.rb as a workaround for https://bugs.ruby-lang.org/issues/17123
		echo RUBY_MAJOR=$RUBY_MAJOR
		echo RUBY_MAJOR=$RUBY_MINOR
		run sed -i '/ncurses/d' ext/readline/extconf.rb
	fi
	run make -j$CONCURRENCY Q= V=1 exts.mk
	run make -j$CONCURRENCY Q= V=1
	echo
fi


header "Installing into temporary prefix"
run rm -rf /tmp/ruby
run make install-nodoc
echo


header "Postprocessing build output"

# Copy over non-statically linked third-party libraries and other files.
if [[ "$NAME" = x86 ]]; then
	USRLIBDIR=/usr/lib
else
	USRLIBDIR=/usr/lib64
fi
header "finding libs"
find -name libyam*  
find -name psy*
find -name libffi*
header "checking usr lib dir"
run ls $USRLIBDIR
run ls /usr/lib
run ls /hbb_shlib/lib
run cp $USRLIBDIR/libtinfo.so.5 /tmp/ruby/lib/
if [[ $RUBY_MAJOR -lt 3 || $RUBY_MAJOR -eq 3 && $RUBY_MINOR -lt 3 ]]; then
	run cp $USRLIBDIR/libreadline.so.6 /tmp/ruby/lib/
fi

run cp /system_shared/ca-bundle.crt /tmp/ruby/lib/
run cp /system/traveling_ruby_restore_environment.rb /tmp/ruby/lib/ruby/site_ruby/
export SSL_CERT_FILE=/tmp/ruby/lib/ca-bundle.crt

# Dump various information about the Ruby binaries.
RUBY_COMPAT_VERSION=`/tmp/ruby/bin/ruby -rrbconfig -e 'puts RbConfig::CONFIG["ruby_version"]'`
RUBY_ARCH=`/tmp/ruby/bin/ruby -rrbconfig -e 'puts RbConfig::CONFIG["arch"]'`
GEM_PLATFORM=`/tmp/ruby/bin/ruby -e 'puts Gem::Platform.local.to_s'`
GEM_EXTENSION_API_VERSION=`/tmp/ruby/bin/ruby -e 'puts Gem.extension_api_version'`
run mkdir /tmp/ruby/info
echo "+ Dumping information about the Ruby binaries into /tmp/ruby/info"
echo $RUBY_COMPAT_VERSION > /tmp/ruby/info/RUBY_COMPAT_VERSION
echo $RUBY_ARCH > /tmp/ruby/info/RUBY_ARCH
echo $GEM_PLATFORM > /tmp/ruby/info/GEM_PLATFORM
echo $GEM_EXTENSION_API_VERSION > /tmp/ruby/info/GEM_EXTENSION_API_VERSION

# Install gem-specific library dependencies.
run mkdir -p /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/deplibs/$GEM_PLATFORM
pushd /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/deplibs/$GEM_PLATFORM
run mkdir curses && run cp $USRLIBDIR/{libncursesw.so.5,libmenuw.so.5,libformw.so.5} curses/



## If installing libffi from source
# run cp /hbb_shlib/lib64/{libffi.so.8,libffi.so.8.1.2} /tmp/ruby/lib/

# ## If using libffi included in the holy build box system
run cp $USRLIBDIR/{libffi.so.6,libffi.so.6.0.1} /tmp/ruby/lib/
popd

echo "Patching rbconfig.rb"
echo >> /tmp/ruby/lib/ruby/$RUBY_COMPAT_VERSION/$RUBY_ARCH/rbconfig.rb
cat "/system/rbconfig_patch.rb" >> /tmp/ruby/lib/ruby/$RUBY_COMPAT_VERSION/$RUBY_ARCH/rbconfig.rb

# Remove some standard dummy gems. We must do this before
# installing further gems in order to prevent accidentally
# removing explicitly gems.
run rm -rf /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/{test-unit,rdoc}-*

function install_gems()
{

	for GEMFILE in /system_shared/gemfiles/*/Gemfile; do
		run cp "$GEMFILE" /tmp/ruby/
		if [[ -e "$GEMFILE.lock" ]]; then
			run cp "$GEMFILE.lock" /tmp/ruby/
		fi
		echo "+ Entering /tmp/ruby"
		pushd /tmp/ruby >/dev/null
		run /tmp/ruby/bin/bundle config set --local system true
		run /tmp/ruby/bin/bundle install --retry 3 --jobs $CONCURRENCY
		run rm Gemfile*
		echo "+ Leaving /tmp/ruby"
		popd >/dev/null
	done
}

function open_debug_shell()
{
	export EDITOR=nano
	export TERM=xterm-256color
	export PATH=/tmp/ruby/bin:$PATH
	unset PROMPT_COMMAND
	if [[ ! -e /usr/bin/nano ]]; then
		echo
		echo "----------- Preparing debugging shell -----------"
		run yum install -y nano
	fi
	echo
	echo "-------------------------------------------"
	echo "A debugging shell will be opened for you."
	pushd /tmp/ruby/lib/ruby/gems/* >/dev/null
	bash --noprofile --norc || true
	popd >/dev/null
}

export DEFAULT_LDFLAGS=`/tmp/ruby/bin/ruby -rrbconfig -e 'puts RbConfig::CONFIG["LDFLAGS"]'`
export BUNDLE_BUILD__CHARLOCK_HOLMES=--with-ldflags="'$DEFAULT_LDFLAGS -Wl,--whole-archive -licui18n -licuuc -licudata -Wl,--no-whole-archive -lstdc++'"
export BUNDLE_BUILD__RUGGED=--with-ldflags="'$DEFAULT_LDFLAGS -Wl,--whole-archive -lssl -lcrypto -Wl,--no-whole-archive'"
export BUNDLE_BUILD__PUMA=--with-ldflags="'$DEFAULT_LDFLAGS -lz'"
export BUNDLE_BUILD__EVENTMACHINE=--with-ldflags="'$DEFAULT_LDFLAGS -lz'"
export BUNDLE_BUILD__SQLLITE=--with-ldflags="'$DEFAULT_LDFLAGS -lz'"
export BUNDLE_BUILD__MYSQL2="--with-system-libraries"

if [[ "$DEBUG_SHELL" = before ]]; then
	open_debug_shell
fi
if [[ -e /system_shared/gemfiles ]]; then

	header "Updating RubyGems..."

	if /tmp/ruby/bin/gem --version | grep -q $RUBYGEMS_VERSION; then
		echo "RubyGems is up to date."
	else
		echo "RubyGems is out of date, updating..."
		run /tmp/ruby/bin/gem update --system  $RUBYGEMS_VERSION --no-document
	fi
	run /tmp/ruby/bin/gem uninstall -x rubygems-update
	run /tmp/ruby/bin/gem install bundler -v $BUNDLER_VERSION --no-document
	if [[ "$DEBUG_SHELL" = after ]]; then
		install_gems || true
	else
		install_gems
	fi
fi
if [[ "$DEBUG_SHELL" = after ]]; then
	open_debug_shell
fi

# Strip binaries and remove unnecessary files.
run strip --strip-all /tmp/ruby/bin/ruby
(
	set -o pipefail
	echo "+ Stripping .so files"
	find /tmp/ruby -name '*.so' | xargs strip --strip-debug
)
if [[ $? != 0 ]]; then
	exit 1
fi
run rm /tmp/ruby/bin/{erb,rdoc,ri}
run rm -f /tmp/ruby/bin/testrb # Only Ruby 2.1 has it
run rm -rf /tmp/ruby/include
run rm -rf /tmp/ruby/share
run rm -rf /tmp/ruby/lib/{libruby*static.a,pkgconfig}
run rm -rf /tmp/ruby/lib/ruby/$RUBY_COMPAT_VERSION/rdoc/generator/
run rm -rf /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/cache/*
run rm -f /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/extensions/$GEM_PLATFORM/$GEM_EXTENSION_API_VERSION/*/{gem_make.out}
run rm -rf /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/{test,spec,*.md,*.rdoc}
run rm -rf /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/ext/*/*.{c,h}

# removes rugged libgit2 vendor folder
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/vendor | xargs rm -rf
# Delete every bundled gem except for the bundled version of ruby
header "Removing bundled gems for versions other than $RUBY_MAJOR_MINOR" 
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/lib/*/*.*/ -name '*.so'
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/lib/*/*.*/ -name '*.so' -not -path "*/$RUBY_MAJOR_MINOR/*"
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/lib/*/*.*/ -name '*.so' -not -path "*/$RUBY_MAJOR_MINOR/*" | xargs rm -rf
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/rugg*/  -name '*.so' | xargs rm -rf
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/char*/  -name '*.so' | xargs rm -rf
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/pg*/  -name '*.so' | xargs rm -rf
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/event*/  -name '*.so' | xargs rm -rf
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/puma*/  -name '*.so' | xargs rm -rf
find /tmp/ruby/lib -type f -name '*.java'| xargs rm -f
find /tmp/ruby/lib -type f -name '*.class'| xargs rm -f
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/*/contrib -type f | grep -v '.rb$'| xargs rm -f
find . -name '.travis.yml'| xargs rm -rf
find . -name '.github'| xargs rm -rf
## Remove all .o and .so files, we will use the extensions folder
# with exception to nokogiri and sqlite
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems -name '*.o' | xargs rm -f
find /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems -name '*.so' -not -path '*sqlite*' -not -path '*nokogiri*' | xargs rm -f

if [[ -e /system_shared/gemfiles ]]; then
	echo "+ Entering Bundler gem directory"
	pushd /tmp/ruby/lib/ruby/gems/$RUBY_COMPAT_VERSION/gems/bundler-$BUNDLER_VERSION >/dev/null
	rm -rf .gitignore .rspec .travis.yml man Rakefile lib/bundler/man/*.txt lib/bundler/templates
	popd >/dev/null
	echo "+ Leaving Bundler gem directory"
fi

# Create wrapper scripts
mv /tmp/ruby/bin /tmp/ruby/bin.real
mkdir /tmp/ruby/bin
create_environment_file /tmp/ruby/bin/ruby_environment
create_wrapper /tmp/ruby/bin/ruby ruby false
create_wrapper /tmp/ruby/bin/gem gem true
create_wrapper /tmp/ruby/bin/irb irb true
create_wrapper /tmp/ruby/bin/rake rake true
if [[ -e /system_shared/gemfiles ]]; then
	create_wrapper /tmp/ruby/bin/bundle bundle true
	create_wrapper /tmp/ruby/bin/bundler bundler true
fi
echo

## Skip order of sanity check, so we still perform it but retain our 
## build output for further testing
header "Committing build output"
run chown -R $APP_UID:$APP_GID /tmp/ruby
run mv /tmp/ruby/* /output/

find /output -name '*.so*'

if $SANITY_CHECK_OUTPUT; then
	header "Sanity checking build output"
	env LIBCHECK_ALLOW='libreadline|libtinfo|libformw|libmenuw|libncursesw' \
		libcheck /output/bin.real/ruby $(find /output -name '*.so')
fi