# FIXME: minimal supported deployment target on x86_64 and ARM64?
# NOTE: it looks like this is used only for building PostgreSQL
# export MACOSX_DEPLOYMENT_TARGET=12.1
# FIXME: a full list of deployment targets on ARM64
# FIXME: not used at all?
# export MACOSX_COMPATIBLE_DEPLOYMENT_TARGETS="10.14 10.15 11.0 11.1 11.2 11.3 11.4 11.5 11.6 12.0 12.1"
export PATH="$SELFDIR/internal/bin":/usr/bin:/bin:/usr/sbin:/sbin
export CC="$SELFDIR/internal/bin/cc"
export CXX="$SELFDIR/internal/bin/c++"
unset DYLD_LIBRARY_PATH
unset DYLD_INSERT_LIBRARIES
unset CFLAGS
unset CXXFLAGS
unset LDFLAGS
unset RUBYOPT
unset RUBYLIB
unset GEM_HOME
unset GEM_PATH
unset SSL_CERT_DIR
unset SSL_CERT_FILE
