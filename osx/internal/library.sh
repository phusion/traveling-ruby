RESET=`perl -e 'print("\e[0m")'`
BOLD=`perl -e 'print("\e[1m")'`
YELLOW=`perl -e 'print("\e[33m")'`
BLUE_BG=`perl -e 'print("\e[44m")'`

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
