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

trap cleanup EXIT

export PATH="$SELFDIR/internal/bin":/usr/bin:/bin:/usr/sbin:/sbin
export MACOSX_DEPLOYMENT_TARGET=10.8
export MACOSX_COMPATIBLE_DEPLOYMENT_TARGETS="10.8 10.9 10.10 10.11"
export CC="$SELFDIR/internal/bin/cc"
export CXX="$SELFDIR/internal/bin/c++"
unset DYLD_LIBRARY_PATH
unset DYLD_INSERT_LIBRARIES
unset CFLAGS
unset CXXFLAGS
unset LDFLAGS
