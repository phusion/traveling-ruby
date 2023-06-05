#!/bin/sh -e
## Tested with https://www.shellcheck.net/
# Usage: (install latest release & latest ruby version)
#   $ curl -fsSL https://raw.githubusercontent.com/you54f/traveling-ruby/main/install.sh | sh
# or
#   $ wget -q https://raw.githubusercontent.com/you54f/traveling-ruby/main/install.sh -O- | sh

# Options
# TRAVELING_RUBY_VERSION - set ruby version eg TRAVELING_RUBY_VERSION=2.7.3
# TRAVELING_RUBY_RELEASE_TAG - set release tag eg TRAVELING_RUBY_RELEASE_TAG=rel20230605
# TRAVELING_RUBY_INSTALL_PATH - set install path eg TRAVELING_RUBY_INSTALL_PATH=$HOME/.travelling-ruby
# TRAVELING_RUBY_CLEAN_INSTALL - set to true to remove existing install eg TRAVELING_RUBY_CLEAN_INSTALL=true

# Usage: (install fixed version of a release) -
#   $ curl -fsSL https://raw.githubusercontent.com/you54f/traveling-ruby/main/install.sh | TRAVELING_RUBY_RELEASE_TAG=rel-20230605 sh
# or
#   $ wget -q https://raw.githubusercontent.com/you54f/traveling-ruby/main/install.sh -O- | TRAVELING_RUBY_RELEASE_TAG=rel-20230605 sh

# Usage: (install fixed version of ruby) -
#   $ curl -fsSL https://raw.githubusercontent.com/you54f/traveling-ruby/main/install.sh | TRAVELING_RUBY_VERSION=2.6.10 sh
# or
#   $ wget -q https://raw.githubusercontent.com/you54f/traveling-ruby/main/install.sh -O- | TRAVELING_RUBY_VERSION=2.6.10 sh

PROJECT_NAME='traveling-ruby'
TRAVELING_RUBY_GH_SOURCE=YOU54F/${PROJECT_NAME}
TRAVELING_RUBY_VERSION=${TRAVELING_RUBY_VERSION:-3.2.2}

usage() {
  echo "Usage: $0 [-v <version>] [-d <release-date>] [--set-path] [--clean-install] [--ci]"
  echo ""
  echo "  -v <version>          Ruby version to install (default: 3.2.2)"
  echo "  -d <release-date>     Release date of the traveling ruby package to download (default: latest)"
  echo "  --set-path            Add the traveling ruby bin path to the PATH environment variable (default: false)"
  echo "  --clean-install       Remove any existing traveling ruby installation before installing (default: false)"
  echo "  --ci                  Set --set-path to true and --clean-install to true (default: false)"
  exit 0
}

while getopts "hv:d:-:" opt; do
  case $opt in
  v)
    TRAVELING_RUBY_VERSION=$OPTARG
    ;;
  d)
    TRAVELING_RUBY_PKG_DATE=$OPTARG
    ;;
  h)
  usage
  ;;
  -)
    case "${OPTARG}" in
    set-path)
      TRAVELING_RUBY_SET_PATH=true
      ;;
    clean-install)
      TRAVELING_RUBY_CLEAN_INSTALL=true
      ;;
    ci)
      TRAVELING_RUBY_SET_PATH=true
      TRAVELING_RUBY_CLEAN_INSTALL=true
      ;;
    * | h)
      usage
      ;;
    esac
    ;;
  esac
done

if [ -z "$TRAVELING_RUBY_VERSION" ]; then
  TRAVELING_RUBY_VERSION=3.2.2
fi

if [ -z "$TRAVELING_RUBY_PKG_DATE" ]; then
  TRAVELING_RUBY_RELEASE_TAG=$(basename "$(curl -fs -o/dev/null -w "%{redirect_url}" https://github.com/${TRAVELING_RUBY_GH_SOURCE}/releases/latest)")
  TRAVELING_RUBY_PKG_DATE=$(echo "$TRAVELING_RUBY_RELEASE_TAG" | cut -d '-' -f 2)
  echo "Thanks for downloading the latest release of ${PROJECT_NAME} $TRAVELING_RUBY_RELEASE_TAG."
  echo "-------------"
  echo "Note:"
  echo "-------------"
  echo "You can download a fixed version by setting the TRAVELING_RUBY_RELEASE_TAG environment variable eg TRAVELING_RUBY_RELEASE_TAG=$TRAVELING_RUBY_RELEASE_TAG"
  echo "example:"
  echo "  curl -fsSL https://raw.githubusercontent.com/${TRAVELING_RUBY_GH_SOURCE}/main/install.sh | TRAVELING_RUBY_RELEASE_TAG=$TRAVELING_RUBY_RELEASE_TAG sh"
else
  echo "Thanks for downloading ${PROJECT_NAME} version $PACT_CLI_VERSION."
fi

echo "-------------"
echo "You can download a fixed ruby version by setting the TRAVELING_RUBY_VERSION environment variable eg TRAVELING_RUBY_VERSION=$TRAVELING_RUBY_VERSION"
echo "example:"
echo "  curl -fsSL https://raw.githubusercontent.com/${TRAVELING_RUBY_GH_SOURCE}/main/install.sh | TRAVELING_RUBY_VERSION=$TRAVELING_RUBY_VERSION sh"
echo "-------------"

echo "detecting platform & architecture"
case $(uname -sm) in
'Linux x86_64')
  TRAVELING_RUBY_OS=linux
  TRAVELING_RUBY_ARCH=x86_64
  ;;
'Linux aarch64')
  TRAVELING_RUBY_OS=linux
  TRAVELING_RUBY_ARCH=arm64
  ;;
'Darwin arm64')
  TRAVELING_RUBY_OS=osx
  TRAVELING_RUBY_ARCH=arm64
  ;;
'Darwin x86_64')
  TRAVELING_RUBY_OS=osx
  TRAVELING_RUBY_ARCH=x86_64
  ;;
"Windows"* | "MINGW64"*)
  TRAVELING_RUBY_OS=windows
  TRAVELING_RUBY_ARCH=x86_64
  ;;
*)
  echo "Sorry, you'll need to install the ${PROJECT_NAME} manually."
  exit 1
  ;;
esac

TRAVELING_RUBY_PLATFORM="${TRAVELING_RUBY_OS}-${TRAVELING_RUBY_ARCH}"
TRAVELING_RUBY_INSTALL_PATH="${TRAVELING_RUBY_INSTALL_PATH:-$HOME/.travelling-ruby}"
TRAVELING_RUBY_BASENAME=traveling-ruby-${TRAVELING_RUBY_PKG_DATE}-${TRAVELING_RUBY_VERSION}-${TRAVELING_RUBY_PLATFORM}
TRAVELING_RUBY_FILENAME="${TRAVELING_RUBY_BASENAME}.tar.gz"
TRAVELING_RUBY_BIN_PATH="${TRAVELING_RUBY_INSTALL_PATH}/bin"
echo "-------------"
echo "TRAVELING_RUBY_PKG_DATE: $TRAVELING_RUBY_PKG_DATE"
echo "TRAVELING_RUBY_VERSION: $TRAVELING_RUBY_VERSION"
echo "TRAVELING_RUBY_OS: $TRAVELING_RUBY_OS"
echo "TRAVELING_RUBY_ARCH: $TRAVELING_RUBY_ARCH"
echo "TRAVELING_RUBY_PLATFORM: $TRAVELING_RUBY_PLATFORM"
echo "TRAVELLING_RUBY_BASENAME: $TRAVELING_RUBY_BASENAME"
echo "TRAVELING_RUBY_GH_SOURCE: $TRAVELING_RUBY_GH_SOURCE"
echo "TRAVELING_RUBY_INSTALL_PATH: $TRAVELING_RUBY_INSTALL_PATH"
echo "TRAVELING_RUBY_FILENAME: $TRAVELING_RUBY_FILENAME"

if [ "$TRAVELING_RUBY_CLEAN_INSTALL" = "true" ]; then
  echo "-------------"
  echo "Cleaning up ${PROJECT_NAME} @ $TRAVELING_RUBY_INSTALL_PATH"
  rm -rf $TRAVELING_RUBY_INSTALL_PATH
fi

mkdir -p $TRAVELING_RUBY_INSTALL_PATH
cd $TRAVELING_RUBY_INSTALL_PATH

echo "-------------"
echo "Downloading:"
echo "-------------"
echo "curl --fail -LO https://github.com/${TRAVELING_RUBY_GH_SOURCE}/releases/download/"${TRAVELING_RUBY_RELEASE_TAG}"/"${TRAVELING_RUBY_FILENAME}""
(curl --fail -LO https://github.com/${TRAVELING_RUBY_GH_SOURCE}/releases/download/"${TRAVELING_RUBY_RELEASE_TAG}"/"${TRAVELING_RUBY_FILENAME}" && echo downloaded "${TRAVELING_RUBY_FILENAME}") || (echo "Sorry, you'll need to install the ${PROJECT_NAME} manually." && exit 1)
(tar xzf "${TRAVELING_RUBY_FILENAME}" && echo unarchived "${TRAVELING_RUBY_FILENAME}") || (echo "Sorry, you'll need to unarchived ${PROJECT_NAME} manually." && exit 1)
(rm "${TRAVELING_RUBY_FILENAME}" && echo removed "${TRAVELING_RUBY_FILENAME}") || (echo "Sorry, you'll need to remove ${PROJECT_NAME} archive manually." && exit 1)

echo "${PROJECT_NAME} ${TRAVELING_RUBY_RELEASE_TAG} installed to $TRAVELING_RUBY_INSTALL_PATH"
echo "-------------------"
echo "Successfully installed ${PROJECT_NAME} to:"
echo "  $TRAVELING_RUBY_INSTALL_PATH:"
echo "-------------------"
echo "ls -1 $TRAVELING_RUBY_INSTALL_PATH"
echo "-------------------"
ls -1 $TRAVELING_RUBY_INSTALL_PATH
echo "-------------------"
echo "$TRAVELING_RUBY_BIN_PATH/ruby --version"
echo "-------------------"

$TRAVELING_RUBY_BIN_PATH/ruby --version || echo "Sorry, we couldnt find the right path to ruby to check the installed. Please check your installation at $TRAVELING_RUBY_BIN_PATH!"
echo "-------------------"

if [ $TRAVELING_RUBY_SET_PATH ]; then
  if [ $GITHUB_ENV ]; then
    echo "Added the following to your path to make ${PROJECT_NAME} available:"
    echo ""
    echo "PATH=$TRAVELING_RUBY_BIN_PATH:\${PATH}"
    echo "PATH=${PATH}:$TRAVELING_RUBY_BIN_PATH" >>$GITHUB_ENV
  elif [ $CIRRUS_CI ]; then
    echo "Added the following to your path to make ${PROJECT_NAME} available:"
    echo ""
    echo "PATH=$TRAVELING_RUBY_BIN_PATH:\${PATH}"
    echo "PATH=$TRAVELING_RUBY_BIN_PATH:${PATH}" >>$CIRRUS_ENV
  else
    echo "Add the following to your path to make ${PROJECT_NAME} available:"
    echo "--- Linux/MacOS/Windows Bash Users --------"
    echo ""
    echo "  PATH=:$TRAVELING_RUBY_BIN_PATH:\${PATH}"
  fi
fi
