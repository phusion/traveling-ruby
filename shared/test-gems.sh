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
	while getopts "hap:" opt; do
		case "$opt" in
		h)
			usage
			exit
			;;
		p)
			PLATFORM="$OPTARG"
			;;
		a)
			ARCHITECTURE="$OPTARG"
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

	if [[ "$PLATFORM" = "" ]]; then
		PLATFORM=$(uname | tr '[:upper:]' '[:lower:]')
		if [[ "$PLATFORM" = "darwin" ]]; then
			PLATFORM="osx"
		fi
	fi

	if [[ "$PLATFORM" != "" && "$PLATFORM" != "osx" && "$PLATFORM" != "windows" && "$PLATFORM" != "linux" ]]; then
		echo "ERROR: Invalid platform specified. Must be 'osx', 'windows', or 'linux'."
		exit 1
	fi

	if [[ "$ARCHITECTURE" = "" ]]; then
		if [[ "$BUILD_OUTPUT_DIR" == *"arm64"* ]]; then
			ARCHITECTURE="arm64"
		elif [[ "$BUILD_OUTPUT_DIR" == *"x86_64"* ]]; then
			ARCHITECTURE="x86_64"
		fi
	fi

	if [[ "$ARCHITECTURE" != "" && "$ARCHITECTURE" != "arm64" && "$ARCHITECTURE" != "x86_64" ]]; then
		echo "ERROR: Invalid architecture specified. Must be 'arm64' or 'x86_64'."
		exit 1
	fi
}


parse_options "$@"


##########

GEMS_TO_TEST=(
	rexml 
	nio 
	socket 
	rinda/ring 
	rinda/tuplespace
	openssl readline rugged charlock_holmes unf_ext bcrypt RedCloth
	eventmachine escape_utils json nokogiri ffi pg posix-spawn
	thin sqlite3 yajl puma/puma_http11 kgio raindrops fast-stemmer
	hitimes redcarpet curses
	mysql2
	)
GEMS_TO_FAIL=(
	"win32ole"
	) 
GEMS_TO_SKIP=(
	mysql2
	"sinatra"
	"nio4r" 
	test-unit 
	"rinda"
)

if [[ "$BUILD_OUTPUT_DIR" == *"3.0.4"* ]]; then
	GEMS_TO_FAIL+=("debug")
fi

echo "Testing gems in $BUILD_OUTPUT_DIR"
echo "Platform: $PLATFORM"
echo "Architecture: $ARCHITECTURE"
echo "Gems to test: ${GEMS_TO_TEST[@]}"
echo "Gems to fail: ${GEMS_TO_FAIL[@]}"

header "Listing gems versions in $BUILD_OUTPUT_DIR"
GEM_LIST=$("$BUILD_OUTPUT_DIR/bin/gem" list)
echo "$GEM_LIST"
echo "$GEM_LIST" >> "$BUILD_OUTPUT_DIR/test_report"
# header "modifying gem names in $BUILD_OUTPUT_DIR for testing"
# "$BUILD_OUTPUT_DIR/bin/gem" list | awk '{gsub(/io-/, "io/"); gsub(/net-/, "net/"); sub(/-ext/, ""); sub(/-ruby/, ""); print $1}' | grep -v -- "-ext"

GEMS=($("$BUILD_OUTPUT_DIR/bin/gem" list | awk '{gsub(/io-/, "io/"); gsub(/net-/, "net/"); gsub(/pact-provider-verifier/, "pact/provider_verifier/cli/verify"); gsub(/pact_broker-client/, "pact_broker/client/tasks"); gsub(/pact-/, "pact/"); gsub(/faraday-/, "faraday/"); sub(/-ext/, ""); sub(/-ruby/, ""); sub(/english/, "English"); print $1}' | grep -v -- "-ext"))
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
	if [[ " ${GEMS_TO_SKIP[@]} " =~ " ${LIB} " ]]; then # Check if the current gem is in the GEMS_TO_SKIP array
		warning "Skipping gem $LIB"
		continue
	fi
	if ! "$BUILD_OUTPUT_DIR/bin/ruby" -r$LIB -e true ; then
		if [[ ! " ${GEMS_TO_FAIL[@]} " =~ " ${LIB} " ]]; then # Check if the current gem is not in the GEMS_TO_FAIL array
			ERRORS+=("$LIB")
		else # If the current gem is in the GEMS_TO_FAIL array, then it's OK
			warning "Gem $LIB failed to load but exit code supressed. "
		fi
	else
		success "Gem $LIB OK!"
		if [[ "$LIB" == "pact/ffi" ]]; then
		echo "Testing pact-ffi gem loads shared library (via ffi gem)"
		"$BUILD_OUTPUT_DIR/bin/ruby" -r$LIB -e "puts PactFfi.pactffi_version"
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