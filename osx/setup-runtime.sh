#!/bin/bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/internal/reset_environment.sh"
source "$SELFDIR/../shared/library.sh"

TEMPDIR=

RUNTIME_DIR=
ARCHITECTURE=$(uname -m)
CONCURRENCY=$(sysctl -n hw.ncpu)
FORCE_CCACHE=false
SKIP_CCACHE=false
FORCE_CMAKE=false
SKIP_CMAKE=false
FORCE_PKG_CONFIG=false
SKIP_PKG_CONFIG=false
FORCE_AUTOCONF=false
SKIP_AUTOCONF=false
FORCE_AUTOMAKE=false
SKIP_AUTOMAKE=false
FORCE_LIBTOOL=false
SKIP_LIBTOOL=false
FORCE_OPENSSL=false
SKIP_OPENSSL=false
FORCE_NCURSES=false
SKIP_NCURSES=false
FORCE_LIBEDIT=false
SKIP_LIBEDIT=false
FORCE_GMP=false
SKIP_GMP=false
FORCE_LIBFFI=false
SKIP_LIBFFI=false
FORCE_LIBYAML=false
SKIP_LIBYAML=false
FORCE_SQLITE3=false
SKIP_SQLITE3=false
FORCE_LIBLZMA=false
SKIP_LIBLZMA=false
FORCE_MYSQL=false
SKIP_MYSQL=false
FORCE_POSTGRESQL=false
SKIP_POSTGRESQL=false
FORCE_ICU=false
SKIP_ICU=false
FORCE_LIBSSH2=false
SKIP_LIBSSH2=false
FORCE_LIBXML2=false
SKIP_LIBXML2=false
FORCE_LIBXSLT=false
SKIP_LIBXSLT=false

function _cleanup()
{
	if [[ "$TEMPDIR" != "" ]]; then
		rm -rf "$TEMPDIR"
	fi
}

function download_and_extract()
{
	local BASENAME="$1"
	local URL="$2"
	local regex='\.bz2$'

	run rm -f "$BASENAME"
	run curl --fail -L -o "$BASENAME" "$URL"
	if [[ "$URL" =~ $regex ]]; then
		run tar xjf "$BASENAME"
	else
		run tar xzf "$BASENAME"
	fi
	run rm "$BASENAME"
}

function usage()
{
	echo "Usage: ./setup-runtime.sh [options] <RUNTIME DIR>"
	echo "Sets up the Traveling Ruby build system's runtime."
	echo
	echo "Options:"
	echo "  -a NAME        Architecture to setup (e.g. x86_64 or arm64)"
	echo "  -c      Force installing CMake"
	echo "  -C      Skip installing CMake"
	echo "  -o      Force installing OpenSSL"
	echo "  -O      Skip installing OpenSSL"
	echo "  -n      Force installing ncurses"
	echo "  -N      Skip installing ncurses"
	echo "  -e      Force installing libedit"
	echo "  -E      Skip installing libedit"
	echo "  -e      Force installing GMP"
	echo "  -E      Skip installing GMP"
	echo "  -f      Force installing libffi"
	echo "  -F      Skip installing libffi"
	echo "  -y      Force installing libyaml"
	echo "  -Y      Skip installing libyaml"
	echo "  -s      Force installing sqlite3"
	echo "  -S      Skip installing sqlite3"
	echo "  -z      Force installing liblzma"
	echo "  -Z      Skip installing liblzma"
	echo "  -m      Force installing MySQL"
	echo "  -M      Skip installing MySQL"
	echo "  -p      Force installing PostgreSQL"
	echo "  -P      Skip installing PostgreSQL"
	echo "  -k      Force installing PKG_CONFIG"
	echo "  -K      Skip installing PKG_CONFIG"
	echo "  -u      Force installing AUTOMAKE"
	echo "  -U      Skip installing AUTOMAKE"
	echo "  -l      Force installing LIBTOOL"
	echo "  -L      Skip installing LIBTOOL"
	echo "  -i      Force installing ICU"
	echo "  -I      Skip installing ICU"
	echo "  -b      Force installing libssh2"
	echo "  -B      Skip installing libssh2"
	echo "  -x      Force installing libxml2"
	echo "  -X      Skip installing libxml2"
	echo "  -t      Force installing libxslt2"
	echo "  -T      Skip installing libxslt2"
	echo
	echo "  -j NUM  Compilation concurrency. Default: 4"
	echo "  -h      Show this help"
}

function parse_options()
{
	local OPTIND=1
	local opt
	while getopts "a:lLuUkKcCoOnNeEgGfFyYsSzZmMpPiIbBxXtTj:h" opt; do
		case "$opt" in
		a)
			ARCHITECTURE=$OPTARG
			;;
		c)
			FORCE_CMAKE=true
			;;
		C)
			SKIP_CMAKE=true
			;;
		o)
			FORCE_OPENSSL=true
			;;
		O)
			SKIP_OPENSSL=true
			;;
		n)
			FORCE_NCURSES=true
			;;
		N)
			SKIP_NCURSES=true
			;;
		e)
			FORCE_LIBEDIT=true
			;;
		E)
			SKIP_LIBEDIT=true
			;;
		k)
			FORCE_PKG_CONFIG=true
			;;
		K)
			SKIP_PKG_CONFIG=true
			;;
		u)
			FORCE_AUTOMAKE=true
			;;
		U)
			SKIP_AUTOMAKE=true
			;;
		l)
			FORCE_LIBTOOL=true
			;;
		L)
			SKIP_LIBTOOL=true
			;;
		g)
			FORCE_GMP=true
			;;
		G)
			SKIP_GMP=true
			;;
		f)
			FORCE_LIBFFI=true
			;;
		F)
			SKIP_LIBFFI=true
			;;
		y)
			FORCE_LIBYAML=true
			;;
		Y)
			SKIP_LIBYAML=true
			;;
		s)
			FORCE_SQLITE3=true
			;;
		S)
			SKIP_SQLITE3=true
			;;
		z)
			FORCE_LIBLZMA=true
			;;
		Z)
			SKIP_LIBLZMA=true
			;;
		m)
			FORCE_MYSQL=true
			;;
		M)
			SKIP_MYSQL=true
			;;
		p)
			FORCE_POSTGRESQL=true
			;;
		P)
			SKIP_POSTGRESQL=true
			;;
		i)
			FORCE_ICU=true
			;;
		I)
			SKIP_ICU=true
			;;
		b)
			FORCE_LIBSSH2=true
			;;
		B)
			SKIP_LIBSSH2=true
			;;
		x)
			FORCE_LIBXML2=true
			;;
		X)
			SKIP_LIBXML2=true
			;;
		t)
			FORCE_LIBXSLT=true
			;;
		T)
			SKIP_LIBXSLT=true
			;;
		j)
			CONCURRENCY=$OPTARG
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

	if [[ "$RUNTIME_DIR" = "" ]]; then
		usage
		exit 1
	fi
}

echo "Setting up Traveling Ruby's runtime..."
parse_options "$@"
echo "Runtime directory: $RUNTIME_DIR"
mkdir -p "$RUNTIME_DIR"
RUNTIME_DIR="`cd \"$RUNTIME_DIR\" && pwd`"
"$SELFDIR/internal/check_requirements.sh" "$ARCHITECTURE"
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


TOTAL_TOOLS=6
TOTAL_LIBS=14
CCACHE_VERSION=4.9
# https://github.com/ccache/ccache/releases
CMAKE_VERSION=3.28.1
# https://github.com/Kitware/CMake/releases/
PKG_CONFIG_VERSION=0.29.2
# https://pkgconfig.freedesktop.org/releases/
AUTOCONF_VERSION=2.71
# AUTOCONF_VERSION=2.72
# https://ftp.gnu.org/gnu/autoconf/
AUTOMAKE_VERSION=1.16.5
# https://ftp.gnu.org/gnu/automake/
LIBTOOL_VERSION=2.4.7
# https://ftp.gnu.org/gnu/libtool/
# OPENSSL_VERSION=1.1.1w
# OPENSSL_VERSION=3.0.12
# OPENSSL_VERSION=3.1.4
OPENSSL_VERSION=3.2.0
# https://www.openssl.org/source/
NCURSES_VERSION=6.4
# https://ftp.gnu.org/pub/gnu/ncurses/
# https://thrysoee.dk/editline/
LIBEDIT_VERSION=20230828-3.1
LIBEDIT_DIR_VERSION=20230828-3.1
# https://gmplib.org/download/gmp/
GMP_VERSION=6.3.0
GMP_DIR_VERSION=6.3.0
# https://github.com/libffi/libffi/releases/
LIBFFI_VERSION=3.4.4
# https://pyyaml.org/download/libyaml/
LIBYAML_VERSION=0.2.5
# https://www.sqlite.org/download.html
SQLITE3_VERSION=3450000
SQLITE3_VERSION_YEAR=2024
# https://tukaani.org/xz/
XZ_VERSION=5.4.5
MYSQL_LIB_VERSION=6.1.9
# MYSQL_LIB_VERSION=8.3.0
POSTGRESQL_VERSION=15.5
# ICU_RELEASE_VERSION=71-1
# ICU_FILE_VERSION=71_1
# https://github.com/unicode-org/icu/releases/
ICU_RELEASE_VERSION=74-1
ICU_FILE_VERSION=74_1
# https://www.libssh2.org/download/
LIBSSH2_VERSION=1.11.0
# http://xmlsoft.org/download
LIBXML2_VERSION=2.9.14
LIBXSLT_VERSION=1.1.34
# http://xmlsoft.org/download
export PATH="$RUNTIME_DIR/bin:$PATH"
export LIBRARY_PATH="$RUNTIME_DIR/lib"
export PKG_CONFIG_PATH="$RUNTIME_DIR/lib/pkgconfig:/usr/lib/pkgconfig"
export RUNTIME_DIR
export DEAD_STRIP=true

header "Initializing..."
run mkdir -p "$RUNTIME_DIR"
run mkdir -p "$RUNTIME_DIR/ccache"
export CCACHE_DIR="$RUNTIME_DIR/ccache"
export CCACHE_COMPRESS=1
export CCACHE_COMPRESS_LEVEL=3
echo "Entering $RUNTIME_DIR"
cd "$RUNTIME_DIR"
echo

# To many warnings, suppress them all (disable in case of troubleshooting)
export CPPFLAGS="-Wno-error=unused-command-line-argument"
export CXXFLAGS="-Wno-error=unused-command-line-argument"
export CFLAGS="-Wno-error=unused-command-line-argument"

header "Installing tool 1/$TOTAL_TOOLS: CMake..."
if $SKIP_CMAKE; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/bin/cmake" ]] || $FORCE_CMAKE; then
	download_and_extract cmake-$CMAKE_VERSION.tar.gz \
		https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/cmake-$CMAKE_VERSION"
	pushd cmake-$CMAKE_VERSION >/dev/null

	# FIXME: Only on ARM64?
	echo "Removing some false positive checks in CMakeLists"
	patch -u CMakeLists.txt -i $SELFDIR/internal/cmake-3.23.2.patch

	run ./configure --prefix="$RUNTIME_DIR" --no-qt-gui --parallel=$CONCURRENCY
	run make -j$CONCURRENCY
	run make install

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf cmake-$CMAKE_VERSION
else
	echo "Already installed."
fi
echo

header "Installing tool 2/$TOTAL_TOOLS: ccache..."
if $SKIP_CCACHE; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/bin/ccache" ]] || $FORCE_CCACHE; then
	download_and_extract ccache-$CCACHE_VERSION.tar.gz \
		https://github.com/ccache/ccache/releases/download/v$CCACHE_VERSION/ccache-$CCACHE_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/ccache-$CCACHE_VERSION"
	pushd ccache-$CCACHE_VERSION >/dev/null

	mkdir build
	cd build
	run cmake -DCMAKE_OSX_ARCHITECTURES=$ARCHITECTURE -DCMAKE_MACOSX_DEPLOYMENT_TARGET=12.2 -DCMAKE_BUILD_TYPE=Release -DZSTD_FROM_INTERNET=ON -DHIREDIS_FROM_INTERNET=ON -DCMAKE_INSTALL_PREFIX="$RUNTIME_DIR" ..
	run make -j$CONCURRENCY
	run make install

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf ccache-$CCACHE_VERSION
else
	echo "Already installed."
fi
echo

header "Installing tool 3/$TOTAL_TOOLS: pkg-config..."
if $SKIP_PKG_CONFIG; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/bin/pkg-config" ]] || $FORCE_PKG_CONFIG; then
	download_and_extract pkg-config-$PKG_CONFIG_VERSION.tar.gz \
		https://pkgconfig.freedesktop.org/releases/pkg-config-$PKG_CONFIG_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/pkg-config-$PKG_CONFIG_VERSION"
	pushd pkg-config-$PKG_CONFIG_VERSION >/dev/null

	run ./configure --prefix="$RUNTIME_DIR" --with-internal-glib --build=$DEPLOY_TARGET
	run make -j$CONCURRENCY
	run make install
	echo "Entering $RUNTIME_DIR"
	popd >/dev/null
	run rm -rf pkg-config-$PKG_CONFIG_VERSION
else
	echo "Already installed."
fi
echo

header "Installing tool 4/$TOTAL_TOOLS: autoconf..."
if $SKIP_AUTOCONF; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/bin/autoconf" ]] || $FORCE_AUTOCONF; then
	download_and_extract autoconf-$AUTOCONF_VERSION.tar.gz \
		https://ftp.gnu.org/gnu/autoconf/autoconf-$AUTOCONF_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/autoconf-$AUTOCONF_VERSION"
	pushd autoconf-$AUTOCONF_VERSION >/dev/null

	run ./configure --build=$DEPLOY_TARGET --prefix="$RUNTIME_DIR"
	run make -j$CONCURRENCY
	run make install-strip
	echo "Entering $RUNTIME_DIR"
	popd >/dev/null
	run rm -rf autoconf-$AUTOCONF_VERSION
else
	echo "Already installed."
fi
echo

header "Installing tool 5/$TOTAL_TOOLS: automake..."
if $SKIP_AUTOMAKE; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/bin/automake" ]] || $FORCE_AUTOMAKE; then
	download_and_extract automake-$AUTOMAKE_VERSION.tar.gz \
		https://ftp.gnu.org/gnu/automake/automake-$AUTOMAKE_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/automake-$AUTOMAKE_VERSION"
	pushd automake-$AUTOMAKE_VERSION >/dev/null

	run ./configure --build=$DEPLOY_TARGET --prefix="$RUNTIME_DIR"
	run make -j$CONCURRENCY
	run make install-strip
	echo "Entering $RUNTIME_DIR"
	popd >/dev/null
	run rm -rf automake-$AUTOMAKE_VERSION
else
	echo "Already installed."
fi
echo

header "Installing tool 6/$TOTAL_TOOLS: libtool..."
if $SKIP_LIBTOOL; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/bin/libtoolize" ]] || $FORCE_LIBTOOL; then
	download_and_extract libtool-$LIBTOOL_VERSION.tar.gz \
		https://ftp.gnu.org/gnu/libtool/libtool-$LIBTOOL_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/libtool-$LIBTOOL_VERSION"
	pushd libtool-$LIBTOOL_VERSION >/dev/null

	run ./configure --build=$DEPLOY_TARGET --prefix="$RUNTIME_DIR" \
		--disable-shared --enable-static \
		CFLAGS='-O2 -fPIC -fvisibility=hidden'
	run make -j$CONCURRENCY
	run make install-strip
	echo "Entering $RUNTIME_DIR"
	popd >/dev/null
	run rm -rf libtool-$LIBTOOL_VERSION
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 1/$TOTAL_LIBS: OpenSSL..."
if $SKIP_OPENSSL; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/openssl-ok" ]] || $FORCE_OPENSSL; then
	run rm -f openssl-$OPENSSL_VERSION.tar.gz
	run curl --fail -L -O https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
	run tar xzf openssl-$OPENSSL_VERSION.tar.gz
	run rm openssl-$OPENSSL_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/openssl-$OPENSSL_VERSION"
	pushd openssl-$OPENSSL_VERSION >/dev/null


	run ./Configure "$BUILD_TARGET" --prefix="$RUNTIME_DIR" --openssldir="$RUNTIME_DIR/openssl" threads zlib shared
	run make -j$CONCURRENCY
	run make install_sw

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf openssl-$OPENSSL_VERSION

	run chmod u+rw lib/*.dylib
	run rm lib/libcrypto.a
	run rm lib/libssl.a
	run strip bin/openssl
	run strip -S lib/libcrypto.dylib
	run strip -S lib/libssl.dylib
	run install_name_tool -id "@rpath/libssl.3.dylib" \
		"$RUNTIME_DIR/lib/libssl.3.dylib"
	run install_name_tool -change \
		"$RUNTIME_DIR/lib/libcrypto.3.dylib" \
		"@rpath/libcrypto.3.dylib" \
		"$RUNTIME_DIR/lib/libssl.3.dylib"
	run install_name_tool -id "@rpath/libcrypto.3.dylib" \
		"$RUNTIME_DIR/lib/libcrypto.3.dylib"

	run sed -i '' 's/^Libs:.*/Libs: -L${libdir} -lcrypto -lz -ldl -lpthread/' "$RUNTIME_DIR"/lib/pkgconfig/libcrypto.pc
	run sed -i '' '/^Libs.private:.*/d' "$RUNTIME_DIR"/lib/pkgconfig/libcrypto.pc
	touch "$RUNTIME_DIR/lib/openssl-ok"
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 2/$TOTAL_LIBS: ncurses..."
if $SKIP_NCURSES; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libncurses.6.dylib" ]] || $FORCE_NCURSES; then
	run rm -f ncurses-$NCURSES_VERSION.tar.bz2
	run curl --fail -L -O https://ftp.gnu.org/pub/gnu/ncurses/ncurses-$NCURSES_VERSION.tar.gz
	run tar xzf ncurses-$NCURSES_VERSION.tar.gz
	run rm ncurses-$NCURSES_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/ncurses-$NCURSES_VERSION"
	pushd ncurses-$NCURSES_VERSION >/dev/null

	run ./configure --prefix="$RUNTIME_DIR" --with-shared --without-normal --without-cxx --without-cxx-binding \
		--without-ada --without-manpages --without-tests --enable-pc-files \
		--without-develop --build=$DEPLOY_TARGET
	run make -j$CONCURRENCY
	run make install

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf ncurses-$NCURSES_VERSION

	run rm -f "$RUNTIME_DIR/lib"/{libpanel}*
	run rm -f "$RUNTIME_DIR/lib"/{libncurses,libform}*.a
	run strip -S "$RUNTIME_DIR/lib/libncurses.6.dylib"
	run strip -S "$RUNTIME_DIR/lib/libform.6.dylib"
	run strip -S "$RUNTIME_DIR/lib/libmenu.6.dylib"
	run strip -S "$RUNTIME_DIR/lib/libpanel.6.dylib"
	run install_name_tool -id \
		"@rpath/libncurses.6.dylib" \
		"$RUNTIME_DIR/lib/libncurses.6.dylib"
	run install_name_tool -id \
		"@rpath/libmenu.6.dylib" \
		"$RUNTIME_DIR/lib/libmenu.6.dylib"
	run install_name_tool -id \
		"@rpath/libform.6.dylib" \
		"$RUNTIME_DIR/lib/libform.6.dylib"
	run install_name_tool -id \
		"@rpath/libpanel.6.dylib" \
		"$RUNTIME_DIR/lib/libpanel.6.dylib"
	run install_name_tool -change \
		"$RUNTIME_DIR/lib/libncurses.6.dylib" \
		"@rpath/libncurses.6.dylib" \
		"$RUNTIME_DIR/lib/libform.6.dylib"
	run install_name_tool -change \
		"$RUNTIME_DIR/lib/libncurses.6.dylib" \
		"@rpath/libncurses.6.dylib" \
		"$RUNTIME_DIR/lib/libmenu.6.dylib"
	run install_name_tool -change \
		"$RUNTIME_DIR/lib/libncurses.6.dylib" \
		"@rpath/libncurses.6.dylib" \
		"$RUNTIME_DIR/lib/libpanel.6.dylib"
	pushd "$RUNTIME_DIR/lib" >/dev/null
	run ln -sf libncurses.6.dylib libtermcap.dylib

	run file "$RUNTIME_DIR/lib/libncurses.6.dylib"
	run file "$RUNTIME_DIR/lib/libform.6.dylib"

	popd >/dev/null
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 3/$TOTAL_LIBS: libedit..."
if $SKIP_LIBEDIT; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libedit.0.dylib" ]] || $FORCE_LIBEDIT; then
	run rm -f libedit-$LIBEDIT_VERSION.tar.gz
	run curl --fail -L -O https://thrysoee.dk/editline/libedit-$LIBEDIT_VERSION.tar.gz
	run tar xzf libedit-$LIBEDIT_VERSION.tar.gz
	run rm libedit-$LIBEDIT_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/libedit-$LIBEDIT_VERSION"
	pushd libedit-$LIBEDIT_DIR_VERSION >/dev/null

	run ./configure --build=$DEPLOY_TARGET --prefix="$RUNTIME_DIR" --disable-static --enable-widec
	run make -j$CONCURRENCY
	run make install-strip

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf libedit-$LIBEDIT_DIR_VERSION

	pushd "$RUNTIME_DIR/lib" >/dev/null
	run ln -sf libedit.0.dylib libreadline.dylib
	popd >/dev/null
	run install_name_tool -id "@rpath/libedit.0.dylib" \
		"$RUNTIME_DIR/lib/libedit.0.dylib"
	run file "$RUNTIME_DIR/lib/libedit.0.dylib"
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 4/$TOTAL_LIBS: gmp..."
if $SKIP_GMP; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libgmp.10.dylib" ]] || $FORCE_GMP; then
	run rm -f gmp-$GMP_VERSION.tar.bz2
	# https://github.com/actions/runner-images/issues/7901
	# GH Action runners are barred access to https://gmplib.org/download/gmp/gmp-$GMP_VERSION.tar.bz2
	run curl --fail -L -O  https://ftp.gnu.org/gnu/gmp/gmp-$GMP_VERSION.tar.bz2
	run tar xjf gmp-$GMP_VERSION.tar.bz2
	run rm gmp-$GMP_VERSION.tar.bz2
	echo "Entering $RUNTIME_DIR/gmp-$GMP_VERSION"
	pushd gmp-$GMP_DIR_VERSION >/dev/null

	run ./configure --build=$DEPLOY_TARGET --prefix="$RUNTIME_DIR" --enable-static --without-readline --with-pic
	run make -j$CONCURRENCY
	run make install-strip

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf gmp-$GMP_DIR_VERSION

	run install_name_tool -id "@rpath/libgmp.10.dylib" \
		"$RUNTIME_DIR/lib/libgmp.10.dylib"
	run file "$RUNTIME_DIR/lib/libgmp.10.dylib"

else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 5/$TOTAL_LIBS: libffi..."
if $SKIP_LIBFFI; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libffi.8.dylib" ]] || $FORCE_LIBFFI; then
	run rm -f libffi-$LIBFFI_VERSION.tar.bz2
	run curl --fail -L -O https://github.com/libffi/libffi/releases/download/v$LIBFFI_VERSION/libffi-$LIBFFI_VERSION.tar.gz
	run tar xzf libffi-$LIBFFI_VERSION.tar.gz
	run rm libffi-$LIBFFI_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/libffi-$LIBFFI_VERSION"
	pushd libffi-$LIBFFI_VERSION >/dev/null

	run env CFLAGS="-O3 -fomit-frame-pointer -fstrict-aliasing -ffast-math -Wall -fexceptions -fPIC" \
		./configure --build=$DEPLOY_TARGET --prefix="$RUNTIME_DIR" --disable-static --enable-portable-binary
	run make -j$CONCURRENCY
	run make install-strip

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf libffi-$LIBFFI_VERSION
	run file "$RUNTIME_DIR/lib/libffi.8.dylib"

	run install_name_tool -id "@rpath/libffi.8.dylib" \
	  "$RUNTIME_DIR/lib/libffi.8.dylib"
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 6/$TOTAL_LIBS: libyaml..."
if $SKIP_LIBYAML; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libyaml-0.2.dylib" ]] || $FORCE_LIBYAML; then
	download_and_extract yaml-$LIBYAML_VERSION.tar.gz \
		https://pyyaml.org/download/libyaml/yaml-$LIBYAML_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/libyaml-$LIBYAML_VERSION"
	pushd yaml-$LIBYAML_VERSION >/dev/null

	run ./configure --prefix="$RUNTIME_DIR" --disable-static --build=$DEPLOY_TARGET
	run make -j$CONCURRENCY
	run make install-strip

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf yaml-$LIBYAML_VERSION
	run file "$RUNTIME_DIR/lib/libyaml-0.2.dylib"

	run install_name_tool -id "@rpath/libyaml-0.2.dylib" \
		"$RUNTIME_DIR/lib/libyaml-0.2.dylib"
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 7/$TOTAL_LIBS: sqlite3..."
if $SKIP_SQLITE3; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libsqlite3.a" ]] || $FORCE_SQLITE3; then
	download_and_extract sqlite-autoconf-$SQLITE3_VERSION.tar.gz \
		https://www.sqlite.org/$SQLITE3_VERSION_YEAR/sqlite-autoconf-$SQLITE3_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/sqlite-autoconf-$SQLITE3_VERSION"
	pushd sqlite-autoconf-$SQLITE3_VERSION >/dev/null

	run ./configure --prefix="$RUNTIME_DIR" --disable-shared \
		--disable-dynamic-extensions CFLAGS='-O2 -fPIC -fvisibility=hidden' --build=$DEPLOY_TARGET
	run make -j$CONCURRENCY
	run make install-strip
	echo "Entering $RUNTIME_DIR"
	popd >/dev/null
	run rm -rf sqlite-autoconf-$SQLITE3_VERSION
	run lipo -info "$RUNTIME_DIR/lib/libsqlite3.a"
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 8/$TOTAL_LIBS: liblzma..."
if $SKIP_LIBLZMA; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/liblzma.5.dylib" ]] || $FORCE_LIBLZMA; then
	download_and_extract xz-$XZ_VERSION.tar.bz2 \
		https://tukaani.org/xz/xz-$XZ_VERSION.tar.bz2
	echo "Entering $RUNTIME_DIR/xz-$XZ_VERSION"
	pushd xz-$XZ_VERSION >/dev/null

	run ./configure --prefix="$RUNTIME_DIR" --disable-static --disable-xz \
		--disable-xzdec --disable-lzmadec --disable-lzmainfo --disable-lzma-links \
		--disable-scripts --disable-doc --build=$DEPLOY_TARGET
	run make -j$CONCURRENCY
	run make install-strip

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf xz-$XZ_VERSION

	run install_name_tool -id "@rpath/liblzma.5.dylib" \
		"$RUNTIME_DIR/lib/liblzma.5.dylib"
	run file "$RUNTIME_DIR/lib/liblzma.5.dylib"
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 9/$TOTAL_LIBS: MySQL..."
if $SKIP_MYSQL; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libmysqlclient.a" ]] || $FORCE_MYSQL; then
	download_and_extract mysql-connector-c-$MYSQL_LIB_VERSION-src.tar.gz \
		https://dev.mysql.com/get/Downloads/Connector-C/mysql-connector-c-$MYSQL_LIB_VERSION-src.tar.gz
	echo "Entering $RUNTIME_DIR/mysql-connector-c-$MYSQL_LIB_VERSION-src"
	pushd mysql-connector-c-$MYSQL_LIB_VERSION-src >/dev/null

	# We do not use internal/bin/cc and c++ because MySQL includes
	# yassl, which has an OpenSSL compatibility layer. We want the
	# yassl headers to be used, not the OpenSSL headers in the runtime.
	run cmake -DCMAKE_INSTALL_PREFIX="$RUNTIME_DIR" \
		-DCMAKE_C_COMPILER=/usr/bin/cc \
		-DCMAKE_CXX_COMPILER=/usr/bin/c++ \
		-DCMAKE_C_FLAGS="-fPIC -fvisibility=hidden" \
		-DCMAKE_CXX_FLAGS="-fPIC -fvisibility=hidden" . \
		-DDISABLE_SHARED=1 \
		-DCMAKE_VERBOSE_MAKEFILE=1 \
		-DCMAKE_OSX_ARCHITECTURES=$ARCHITECTURE -DCMAKE_MACOSX_DEPLOYMENT_TARGET=12.2
	run make -j$CONCURRENCY libmysql
	run make -C libmysql install
	run make -C include install
	run make -C scripts install

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf mysql-connector-c-$MYSQL_LIB_VERSION-src
	run lipo -info "$RUNTIME_DIR/lib/libmysqlclient.a"
	# https://stackoverflow.com/a/44790834/11598969
	run sed -i '' 's/^libs="$libs -l "*/libs="$libs -l mysqlclient "/' "$RUNTIME_DIR"/bin/mysql_config
else
	echo "Already installed."
fi
echo

# header "Compiling runtime libraries 9/$TOTAL_LIBS: MySQL..."
# if $SKIP_MYSQL; then
# 	echo "Skipped."
# elif [[ ! -e "$RUNTIME_DIR/lib/libmysqlclient.a" ]] || $FORCE_MYSQL; then
# 	download_and_extract mysql-connector-c++-$MYSQL_LIB_VERSION-src.tar.gz \
# 		https://dev.mysql.com/get/Downloads/Connector-C++/mysql-connector-c++-$MYSQL_LIB_VERSION-src.tar.gz
# 	echo "Entering $RUNTIME_DIR/mysql-connector-c++-$MYSQL_LIB_VERSION-src"
# 	pushd mysql-connector-c++-$MYSQL_LIB_VERSION-src >/dev/null

# 	# We do not use internal/bin/cc and c++ because MySQL includes
# 	# yassl, which has an OpenSSL compatibility layer. We want the
# 	# yassl headers to be used, not the OpenSSL headers in the runtime.
# 	run cmake -DCMAKE_INSTALL_PREFIX="$RUNTIME_DIR" \
# 		-DCMAKE_C_COMPILER=/usr/bin/cc \
# 		-DCMAKE_CXX_COMPILER=/usr/bin/c++ \
# 		-DCMAKE_C_FLAGS="-fPIC -fvisibility=hidden" \
# 		-DCMAKE_CXX_FLAGS="-fPIC -fvisibility=hidden" . \
# 		-DDISABLE_SHARED=1 \
# 		-DCMAKE_VERBOSE_MAKEFILE=1
# 		# -DBUILD_STATIC=true \
# 		# -DSTATIC_CONCPP=1
# 	run cmake --build . --config=build_type
# 	# run make -j$CONCURRENCY libmysql
# 	# run make -C libmysql install
# 	# run make -C include install
# 	# run make -C scripts install

# 	echo "Leaving source directory"
# 	popd >/dev/null
# 	run rm -rf mysql-connector-c++-$MYSQL_LIB_VERSION-src
# 	run lipo -info "$RUNTIME_DIR/lib/libmysqlclient.a"
# else
# 	echo "Already installed."
# fi
# echo

header "Compiling runtime libraries 10/$TOTAL_LIBS: PostgreSQL..."
if $SKIP_POSTGRESQL; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libpq.a" ]] || $FORCE_POSTGRESQL; then
	download_and_extract postgresql-$POSTGRESQL_VERSION.tar.bz2 \
		https://ftp.postgresql.org/pub/source/v$POSTGRESQL_VERSION/postgresql-$POSTGRESQL_VERSION.tar.bz2
	echo "Entering $RUNTIME_DIR/postgresql-$POSTGRESQL_VERSION"
	pushd postgresql-$POSTGRESQL_VERSION >/dev/null

	run ./configure --prefix="$RUNTIME_DIR" \
		PG_SYSROOT="$(xcode-select -p)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${MACOSX_DEPLOYMENT_TARGET}.sdk" \
		CFLAGS="-O2 -fPIC -fvisibility=hidden" --build=$DEPLOY_TARGET
	# PostgreSQL's build system sometimes fails when building with
	# concurrency, so we don't do it.
	run make -C src/common
	run make -C src/backend
	run make -C src/interfaces/libpq
	run make -C src/interfaces/libpq install-strip
	run make -C src/include
	run make -C src/include install-strip
	run make -C src/bin/pg_config
	run make -C src/bin/pg_config install-strip

	run rm "$RUNTIME_DIR"/lib/libpq.*
	run mkdir libpq-tmp
	echo "Entering libpq-tmp"
	cd libpq-tmp
	run ar -x ../src/interfaces/libpq/libpq.a
	run ar -x ../src/common/libpgcommon.a
	run ar -x ../src/port/libpgport.a
	run ar -qs "$RUNTIME_DIR"/lib/libpq.a ./*.o
	run strip -x "$RUNTIME_DIR"/lib/libpq.a

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf postgresql-$POSTGRESQL_VERSION
	run lipo -info "$RUNTIME_DIR/lib/libpq.a"
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 11/$TOTAL_LIBS: ICU..."
if $SKIP_ICU; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libicudata.a" ]] || $FORCE_ICU; then
	download_and_extract icu4c-$ICU_FILE_VERSION-src.tgz \
		https://github.com/unicode-org/icu/releases/download/release-$ICU_RELEASE_VERSION/icu4c-$ICU_FILE_VERSION-src.tgz
	echo "Entering $RUNTIME_DIR/icu"
	pushd icu/source >/dev/null

	run ./configure --prefix="$RUNTIME_DIR" --disable-samples --disable-tests \
		--enable-static --disable-shared --with-library-bits=64 --build=$DEPLOY_TARGET \
		CFLAGS="-w -O2 -fPIC -fvisibility=hidden -DU_CHARSET_IS_UTF8=1 -DU_USING_ICU_NAMESPACE=0" \
		CXXFLAGS="-w -O2 -fPIC -fvisibility=hidden -DU_CHARSET_IS_UTF8=1 -DU_USING_ICU_NAMESPACE=0"
	run make -j$CONCURRENCY VERBOSE=1
	run make install -j$CONCURRENCY

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf icu
	run lipo -info "$RUNTIME_DIR/lib/libicudata.a"
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 12/$TOTAL_LIBS: libssh2..."
if $SKIP_LIBSSH2; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libssh2.a" ]] || $FORCE_LIBSSH2; then
	download_and_extract libssh2-$LIBSSH2_VERSION.tar.gz \
		https://www.libssh2.org/download/libssh2-$LIBSSH2_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/libssh2-$LIBSSH2_VERSION"
	pushd libssh2-$LIBSSH2_VERSION >/dev/null

	run ./configure --prefix="$RUNTIME_DIR" --enable-static --disable-shared --build=$DEPLOY_TARGET \
		--with-crypto-openssl --with-libz --disable-examples-build --disable-debug \
		CFLAGS="-w -O2 -fPIC -fvisibility=hidden" \
		CXXFLAGS="-w -O2 -fPIC -fvisibility=hidden"
	run make -j$CONCURRENCY
	run make install-strip -j$CONCURRENCY

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf libssh2-$LIBSSH2_VERSION
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 13/$TOTAL_LIBS: libxml2..."
if $SKIP_LIBXML2; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libxml2.a" ]] || $FORCE_LIBXML2; then
	# FIXME: getting a "Certificate can't be trusted" error while using HTTPS protocol
	LIBXML2_MAJOR_MINOR_VERSION=$(echo $LIBXML2_VERSION | cut -d. -f1-2)
	download_and_extract libxml2-$LIBXML2_VERSION.tar.xz \
		https://download.gnome.org/sources/libxml2/$LIBXML2_MAJOR_MINOR_VERSION/libxml2-$LIBXML2_VERSION.tar.xz
	echo "Entering $RUNTIME_DIR/libxml2-$LIBXML2_VERSION"
	pushd libxml2-$LIBXML2_VERSION >/dev/null

	run ./configure --prefix="$RUNTIME_DIR" --disable-shared --enable-static \
		--without-python --without-readline --without-debug \
		--with-c14n --with-threads --build=$DEPLOY_TARGET \
		CFLAGS="-w -O2 -fPIC -fvisibility=hidden" \
		CXXFLAGS="-w -O2 -fPIC -fvisibility=hidden"
	run make -j$CONCURRENCY
	run make install-strip -j$CONCURRENCY

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf libxml2-$LIBXML2_VERSION
	run lipo -info "$RUNTIME_DIR/lib/libxml2.a"
else
	echo "Already installed."
fi
echo

header "Compiling runtime libraries 14/$TOTAL_LIBS: libxslt..."
if $SKIP_LIBXSLT; then
	echo "Skipped."
elif [[ ! -e "$RUNTIME_DIR/lib/libxslt.a" ]] || $FORCE_LIBXSLT; then
	# FIXME: getting a "Certificate can't be trusted" error while using HTTPS protocol
	download_and_extract libxslt-$LIBXSLT_VERSION.tar.gz \
		http://xmlsoft.org/download/libxslt-$LIBXSLT_VERSION.tar.gz
	echo "Entering $RUNTIME_DIR/libxslt-$LIBXSLT_VERSION"
	pushd libxslt-$LIBXSLT_VERSION >/dev/null

	run ./configure --prefix="$RUNTIME_DIR" --disable-shared --enable-static \
		--without-python --without-debug --without-debugger \
		--without-profiler --build=$DEPLOY_TARGET \
		CFLAGS="-w -O2 -fPIC -fvisibility=hidden" \
		CXXFLAGS="-w -O2 -fPIC -fvisibility=hidden"
		# remove the -w flag here
		# FIXME: getting a "Certificate can't be trusted" error while using HTTPS protocol

	run make -j$CONCURRENCY
	run make install-strip -j$CONCURRENCY

	echo "Leaving source directory"
	popd >/dev/null
	run rm -rf libxslt-$LIBXSLT_VERSION
	run lipo -info "$RUNTIME_DIR/lib/libxslt.a"
else
	echo "Already installed."
fi
echo

header "Checking the architecture of the compiled libraries..."
find $RUNTIME_DIR -type f -path '*.dylib' | xargs file;
find $RUNTIME_DIR -type f -path '*.a' | xargs -I {} lipo -info '{}'
header "All done!"
