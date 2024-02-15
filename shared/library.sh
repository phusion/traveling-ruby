if perl -v >/dev/null 2>/dev/null; then
	RESET=`perl -e 'print("\e[0m")'`
	BOLD=`perl -e 'print("\e[1m")'`
	YELLOW=`perl -e 'print("\e[33m")'`
	RED=`perl -e 'print("\e[31m")'`
	GREEN=`perl -e 'print("\e[32m")'`
	YELLOW_BG=`perl -e 'print("\e[43m")'`
	RED_BG=`perl -e 'print("\e[41m")'`
	GREEN_BG=`perl -e 'print("\e[42m")'`
	BLUE_BG=`perl -e 'print("\e[44m")'`
elif python -V >/dev/null 2>/dev/null; then
	RESET=`echo 'import sys; sys.stdout.write("\033[0m")' | python`
	BOLD=`echo 'import sys; sys.stdout.write("\033[1m")' | python`
	YELLOW=`echo 'import sys; sys.stdout.write("\033[33m")' | python`
	RED=`echo 'import sys; sys.stdout.write("\033[31m")' | python`
	GREEN=`echo 'import sys; sys.stdout.write("\033[32m")' | python`
	YELLOW_BG=`echo 'import sys; sys.stdout.write("\033[43m")' | python`
	RED_BG=`echo 'import sys; sys.stdout.write("\033[41m")' | python`
	GREEN_BG=`echo 'import sys; sys.stdout.write("\033[42m")' | python`
	BLUE_BG=`echo 'import sys; sys.stdout.write("\033[44m")' | python`
else
	RESET=
	BOLD=
	YELLOW=
	RED=
	GREEN=
	RED_BG=
	GREEN_BG=
	BLUE_BG=
fi

function header()
{
	local title="$1"
	echo "${BLUE_BG}${YELLOW}${BOLD}${title}${RESET}"
	echo "------------------------------------------"
}

function warning()
{
	local title="$1"
	echo "${YELLOW}${BOLD}${title}${RESET}"
	echo "------------------------------------------"
}
function success()
{
	local title="$1"
	echo "${GREEN}${BOLD}${title}${RESET}"
	echo "------------------------------------------"
}

function error()
{
	local title="$1"
	echo "${RED}${BOLD}${title}${RESET}"
	echo "------------------------------------------"
}

function run()
{
	echo "+ $@"
	"$@"
}

function absolute_path()
{
	local dir="`dirname \"$1\"`"
	local name="`basename \"$1\"`"
	dir="`cd \"$dir\" && pwd`"
	echo "$dir/$name"
}

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
