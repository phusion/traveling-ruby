#!/bin/sh

# ./scripts/build-docker-images.sh -m -p -v 3.3.0-preview1

# Define the default values for the arguments
DEFAULT_TRAVELING_RUBY_VERSION=2.6.10
DEFAULT_TRAVELING_RUBY_PKG_DATE=20230601
DEFAULT_TRAVELING_RUBY_GH_SOURCE=YOU54F/traveling-ruby
DOCKER_IMAGE_ORG_AND_NAME="you54f/traveling-ruby"

# Define the usage function
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Builds a Docker image for Traveling Ruby."
  echo ""
  echo "Options:"
  echo "  -h, --help                        Show this help message and exit."
  echo "  -v, --version VERSION             Set the Traveling Ruby version (default: ${DEFAULT_TRAVELING_RUBY_VERSION})."
  echo "  -d, --pkg-date PKG_DATE           Set the Traveling Ruby package date (default: ${DEFAULT_TRAVELING_RUBY_PKG_DATE})."
  echo "  -s, --gh-source GH_SOURCE         Set the Traveling Ruby GitHub source (default: ${DEFAULT_TRAVELING_RUBY_GH_SOURCE})."
    echo "  -m, --multi-platform              Build a multi-platform image."
    echo "  -p, --push                        Push the Docker image to the registry."
    echo "  -t, --test [ARCH]                 Test the Docker image by running a container for each image. ARCH defaults to amd64."
    echo "  -a, --arch [ARCH]                 Set the Docker architecture for each image. ARCH defaults to amd64."
  }

  # Parse the command line options
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -v|--version)
        TRAVELING_RUBY_VERSION="$2"
        shift 2
        ;;
      -d|--pkg-date)
        TRAVELING_RUBY_PKG_DATE="$2"
        shift 2
        ;;
      -s|--gh-source)
        TRAVELING_RUBY_GH_SOURCE="$2"
        shift 2
        ;;
      -m|--multi-platform)
        MULTI_PLATFORM=1
        shift
        ;;
      -p|--push)
        PUSH=1
        shift
        ;;
      -t|--test)
        TEST=1
        shift
        ARCH=${1:-"amd64"}
        shift
        ;;
      -a|--arch)
        shift
        ARCH=${1:-"amd64"}
        shift
        ;;
      *)
        echo "Invalid option: $1"
        usage
        exit 1
        ;;
    esac
  done

  echo "Building Docker image for Traveling Ruby version ${TRAVELING_RUBY_VERSION}..."

  # Define the latest major and minor versions
  LATEST_MAJOR_MINOR=("2.7.8" "3.2.2")
  # Set the values for the arguments
  TRAVELING_RUBY_VERSION=${TRAVELING_RUBY_VERSION:-$DEFAULT_TRAVELING_RUBY_VERSION}
  TRAVELING_RUBY_PKG_DATE=${TRAVELING_RUBY_PKG_DATE:-$DEFAULT_TRAVELING_RUBY_PKG_DATE}
  TRAVELING_RUBY_GH_SOURCE=${TRAVELING_RUBY_GH_SOURCE:-$DEFAULT_TRAVELING_RUBY_GH_SOURCE}
  MULTI_PLATFORM=${MULTI_PLATFORM:-0}
  PUSH=${PUSH:-0}
  TEST=${TEST:-0}
  ARCH=${ARCH:-"amd64"}

run_image(){
  docker run --platform linux/${ARCH} --rm -it "${DOCKER_IMAGE_ORG_AND_NAME}:${TAG}" "$1"
}

  if [ "$MULTI_PLATFORM" -eq 1 ]; then
      if [ "$PUSH" -eq 1 ]; then
          PUSH_CMD=",push=true"
      fi
      build_multi(){
        docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --build-arg TRAVELING_RUBY_VERSION=${TRAVELING_RUBY_VERSION} \
        --build-arg TRAVELING_RUBY_PKG_DATE=${TRAVELING_RUBY_PKG_DATE} \
        --build-arg TRAVELING_RUBY_GH_SOURCE=${TRAVELING_RUBY_GH_SOURCE} \
        --output=type=image${PUSH_CMD} \
        --tag ${DOCKER_IMAGE_ORG_AND_NAME}:${TAG} \
        .
      }
      echo "tagging as TRAVELING_RUBY_VERSION=${TRAVELING_RUBY_VERSION}"
      TAG=$TRAVELING_RUBY_VERSION build_multi

      RUBY_MINOR="${TRAVELING_RUBY_VERSION%.*}"
      echo "tagging as RUBY_MINOR=${RUBY_MINOR}"
      TAG=$RUBY_MINOR build_multi

      RUBY_MAJOR="${TRAVELING_RUBY_VERSION%%.*}"
      if [[ " ${LATEST_MAJOR_MINOR[@]} " =~ " ${TRAVELING_RUBY_VERSION} " ]]; then
        echo "tagging as RUBY_MAJOR=${RUBY_MINOR}"
        TAG=$RUBY_MAJOR build_multi
      fi

  elif [ "$TEST" -eq 1 ]; then
    echo "Testing ${TRAVELING_RUBY_VERSION} on ${ARCH}"
    # Check if arch is valid
    arches=("amd64" "arm64")
    if [[ " ${arches[@]} " =~ " ${ARCH} " ]]; then
      # Run a Docker container for each image
      TAG=$TRAVELING_RUBY_VERSION run_image --version
      RUBY_MINOR="${TRAVELING_RUBY_VERSION%.*}"
      TAG=$RUBY_MINOR run_image --version
      RUBY_MAJOR="${TRAVELING_RUBY_VERSION%%.*}"
      if [[ " ${LATEST_MAJOR_MINOR[@]} " =~ " ${TRAVELING_RUBY_VERSION} " ]]; then
        echo "testing RUBY_MAJOR=${RUBY_MINOR}"
          TAG=$RUBY_MAJOR run_image --version
      fi
    else
      echo "Invalid arch parameter. Please set ARCH to one of the following values: ${arches[@]}"
    fi
  else
      echo "Building a local image with the tag ${TRAVELING_RUBY_VERSION}"

      build_single(){
        docker buildx build \
          --platform linux/${ARCH} \
          --build-arg TRAVELING_RUBY_VERSION=${TRAVELING_RUBY_VERSION} \
          --build-arg TRAVELING_RUBY_PKG_DATE=${TRAVELING_RUBY_PKG_DATE} \
          --build-arg TRAVELING_RUBY_GH_SOURCE=${TRAVELING_RUBY_GH_SOURCE} \
          --output=type=docker \
          --tag ${DOCKER_IMAGE_ORG_AND_NAME}:${TAG} \
          .
      }
      echo "testing TRAVELING_RUBY_VERSION=${TRAVELING_RUBY_VERSION}"
      TAG=$TRAVELING_RUBY_VERSION build_single
      TAG=$TRAVELING_RUBY_VERSION run_image --version


      RUBY_MINOR="${TRAVELING_RUBY_VERSION%.*}"
      echo "testing RUBY_MINOR=${RUBY_MINOR}"
      TAG=$RUBY_MINOR build_single
      TAG=$RUBY_MINOR run_image --version

      RUBY_MAJOR="${TRAVELING_RUBY_VERSION%%.*}"
      if [[ " ${LATEST_MAJOR_MINOR[@]} " =~ " ${TRAVELING_RUBY_VERSION} " ]]; then
        echo "testing RUBY_MAJOR=${RUBY_MINOR}"
          TAG=$RUBY_MAJOR build_single
          TAG=$RUBY_MAJOR run_image --version
      fi
  fi