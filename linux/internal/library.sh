RESET=`echo 'import sys; sys.stdout.print("\033[0m")'`
BOLD=`echo 'import sys; sys.stdout.print("\033[1m")'`
YELLOW=`echo 'import sys; sys.stdout.print("\033[33m")'`
BLUE_BG=`echo 'import sys; sys.stdout.print("\033[44m")'`

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
