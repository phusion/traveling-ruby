RESET=`echo 'import sys; sys.stdout.print("\033[0m")' | python`
BOLD=`echo 'import sys; sys.stdout.print("\033[1m")' | python`
YELLOW=`echo 'import sys; sys.stdout.print("\033[33m")' | python`
BLUE_BG=`echo 'import sys; sys.stdout.print("\033[44m")' | python`

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
