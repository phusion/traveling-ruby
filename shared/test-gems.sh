#!/bin/bash
# set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/library.sh"

BUILD_OUTPUT_DIR=

function usage()
{
	echo "Usage: ./test-gems.sh [options] <BUILD OUTPUT DIR>"
	echo "Test the native extension gems."
	echo
	echo "Options:"
	echo "  -h         Show this help"
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

	(( OPTIND -= 1 )) || true
	shift $OPTIND || true
	BUILD_OUTPUT_DIR="$1"

	if [[ "$BUILD_OUTPUT_DIR" = "" ]]; then
		usage
		exit 1
	fi
	if [[ ! -e "$BUILD_OUTPUT_DIR" ]]; then
		echo "ERROR: $BUILD_OUTPUT_DIR doesn't exist."
		exit 1
	fi
}


parse_options "$@"


##########


# GEMS=(openssl readline rugged charlock_holmes unf_ext bcrypt RedCloth
# 	eventmachine escape_utils json nokogiri mysql2 ffi pg posix-spawn
# 	thin sqlite3 yajl puma/puma_http11 kgio raindrops fast-stemmer
# 	hitimes redcarpet curses)

GEMS_TO_TEST=(ffi json rexml yajl)
GEMS_TO_FAIL=("rinda" "test-unit" "win32ole") # Add the gem names that we want to fail

if [[ "$BUILD_OUTPUT_DIR" == *"3.0.4"* ]]; then
	GEMS_TO_FAIL+=("debug")
fi
header "Listing gems versions in $BUILD_OUTPUT_DIR"
GEM_LIST=$("$BUILD_OUTPUT_DIR/bin/gem" list)
echo "$GEM_LIST"
echo "$GEM_LIST" >> "$BUILD_OUTPUT_DIR/test_report"
# header "modifying gem names in $BUILD_OUTPUT_DIR for testing"
"$BUILD_OUTPUT_DIR/bin/gem" list | awk '{gsub(/io-/, "io/"); gsub(/net-/, "net/"); sub(/-ext/, ""); sub(/-ruby/, ""); print $1}' | grep -v -- "-ext"

GEMS=($("$BUILD_OUTPUT_DIR/bin/gem" list | awk '{gsub(/io-/, "io/"); gsub(/net-/, "net/"); sub(/-ext/, ""); sub(/-ruby/, ""); print $1}' | grep -v -- "-ext"))
if [ ${#GEMS[@]} -eq 0 ]; then
	GEMS=("${GEMS_TO_TEST[@]}")
else
	all_gems=("${GEMS[@]}" "${GEMS_TO_TEST[@]}")
	GEMS=("${all_gems[@]}")
fi

header "Testing gems..."
export LD_BIND_NOW=1
export DYLD_BIND_AT_LAUNCH=1
ERRORS=()
for LIB in ${GEMS[@]}; do
	if ! "$BUILD_OUTPUT_DIR/bin/ruby" -r$LIB -e true ; then
		if [[ ! " ${GEMS_TO_FAIL[@]} " =~ " ${LIB} " ]]; then # Check if the current gem is not in the GEMS_TO_FAIL array
			ERRORS+=("$LIB")
		else # If the current gem is in the GEMS_TO_FAIL array, then it's OK
			warning "Gem $LIB failed to load but exit code supressed. "
		fi
	fi
done

if [ ${#ERRORS[@]} -eq 0 ]; then
	success "All gems OK!"
	echo "All gems OK!" > "$BUILD_OUTPUT_DIR/test_report"
else
	error "The following gems failed to load:"
	printf '%s\n' "${ERRORS[@]}"
	echo "The following gems failed to load:" > "$BUILD_OUTPUT_DIR/test_report"
	printf '%s\n' "${ERRORS[@]}" >> "$BUILD_OUTPUT_DIR/test_report"
	exit 1
fi