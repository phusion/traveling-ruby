if perl -v >/dev/null 2>/dev/null; then
	RESET=`perl -e 'print("\e[0m")'`
	BOLD=`perl -e 'print("\e[1m")'`
	YELLOW=`perl -e 'print("\e[33m")'`
	BLUE_BG=`perl -e 'print("\e[44m")'`
elif python -V >/dev/null 2>/dev/null; then
	RESET=`echo 'import sys; sys.stdout.write("\033[0m")' | python`
	BOLD=`echo 'import sys; sys.stdout.write("\033[1m")' | python`
	YELLOW=`echo 'import sys; sys.stdout.write("\033[33m")' | python`
	BLUE_BG=`echo 'import sys; sys.stdout.write("\033[44m")' | python`
else
	RESET=
	BOLD=
	YELLOW=
	BLUE_BG=
fi

function header()
{
	local title="$1"
	echo "${BLUE_BG}${YELLOW}${BOLD}${title}${RESET}"
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
