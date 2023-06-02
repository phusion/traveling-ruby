#!/bin/bash
set -e
set -o pipefail

function cleanup()
{
	set +e
	local pids=`jobs -p`
	if [[ "$pids" != "" ]]; then
		kill $pids 2>/dev/null
	fi
	if [[ `type -t _cleanup` == function ]]; then
		_cleanup
	fi
}

function grep_without_fail()
{
	grep "$@" || true
}

trap cleanup EXIT
DIR="$1"
TAB=`perl -e 'print "\t"'`
ERROR=false
STANDARD_LIBS="(@executable_path/|@rpath/|/usr/lib/libobjc|/usr/lib/libSystem|/usr/lib/libutil|/usr/lib/libz|/usr/lib/liblzma"
STANDARD_LIBS="$STANDARD_LIBS|/usr/lib/libiconv|/usr/lib/libstdc\+\+|/usr/lib/libc\+\+\."
STANDARD_LIBS="$STANDARD_LIBS|CoreFoundation|CoreServices|/Foundation\.framework/|/Security\.framework/)"

for F in $DIR/bin.real/ruby `find $DIR -name '*.bundle'` `find $DIR -name '*.dylib'`; do
	EXTRA_LIBS=`otool -L $F | tail -n +2 | sed "s/^${TAB}//" | sed "s/ (.*//" | grep_without_fail -vE "$STANDARD_LIBS"`
	EXTRA_LIBS=`echo $EXTRA_LIBS`
	if [[ "$EXTRA_LIBS" != "" ]]; then
		echo "$F is linked to non-system libraries:"
		echo "    $EXTRA_LIBS"
		ERROR=true
	fi
done
if $ERROR; then
	echo "Uh Oh."
	exit 1
else
	echo "All OK."
fi
