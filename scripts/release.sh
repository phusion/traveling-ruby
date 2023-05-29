#!/bin/sh

set -e

usage() {
  printf "Usage: release.sh [-h] [-p] [-u] [-d] [-r REPO] [-t TAG] [-n NOTES] [-s]\n"
  printf "Create or update a GitHub release for the current repository.\n\n"
  printf "Options:\n"
  printf "  -h, --help            Show this help message and exit.\n"
  printf "  -p, --pre-release     Create a pre-release.\n"
  printf "  -u, --upload          Upload pre-built files to an existing pre-release.\n"
  printf "  -d, --dry-run         Do not push tags or create releases.\n"
  printf "  -r, --repo REPO       Specify the repository to create the release in. Default is pact-foundation/pact-js-core.\n"
  printf "  -t, --tag TAG         Specify the tag name for the release. Default is rel-<date>-<ruby_version>-<git_sha>.\n"
  printf "  -n, --notes NOTES     Specify the release notes. Default is 'Release date: <date>\\nRuby version: <ruby_version>'.\n"
  printf "  -s, --set-release     Set the pre-release to released.\n"
}

# Default values
REPO="you54f/traveling-ruby"
PKG_DATE=${TRAVELING_RUBY_PKG_DATE:-$(date +%Y%m%d)}
GIT_SHA=$(git rev-parse HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
REL_DATE=$(date +%Y%m%d)
ruby_version=$(ruby -v | awk '{print $2}' | awk -F. '{printf("%d.%d.%d\n",$1,$2,$3)}')
NEXT_TAG="rel-${REL_DATE}-${ruby_version}-${GIT_SHA:0:8}"
RELEASE_NOTES="Release date: ${REL_DATE}\nRuby version: ${ruby_version}"
DRY_RUN=false
CREATE_PRE_RELEASE=false
UPLOAD_PRE_RELEASE=false
UPDATE_PRERELEASE_TO_RELEASED=false

# Parse command line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -p|--pre-release)
      CREATE_PRE_RELEASE=true
      ;;
    -u|--upload)
      UPLOAD_PRE_RELEASE=true
      ;;
    -d|--dry-run)
      DRY_RUN=true
      ;;
    -r|--repo)
      REPO="$2"
      shift
      ;;
    -t|--tag)
      NEXT_TAG="$2"
      shift
      ;;
    -n|--notes)
      RELEASE_NOTES="$2"
      shift
      ;;
    -s|--set-released)
      UPDATE_PRERELEASE_TO_RELEASED=true
      ;;
    *)
      printf "Invalid option: %s\n" "$1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [ "${CREATE_PRE_RELEASE}" = true ]; then
  if gh release view ${NEXT_TAG} --repo ${REPO}>/dev/null; then
    echo "${NEXT_TAG} exists, checking if pre-release"
      if gh release view "${NEXT_TAG}" --repo "${REPO}" --json isPrerelease | jq -e '.isPrerelease == false' >/dev/null; then
        printf "%s exists, and is not a pre-release, exiting\n" "${NEXT_TAG}"
        exit 1
      elif gh release view "${NEXT_TAG}" --repo "${REPO}" --json isPrerelease | jq -e '.isPrerelease == true' >/dev/null; then
        printf "%s exists, and is a pre-release, updating\n" "${NEXT_TAG}"
        gh release edit "${NEXT_TAG}" --prerelease --draft --repo "${REPO}" --title "Release ${NEXT_TAG}" --notes "${RELEASE_NOTES}" --target "${GIT_SHA}"
        exit 0
      fi
    echo "No option found, exiting"
    exit 1
  else
    printf "Creating pre-release %s\n" "${NEXT_TAG}"
    gh release create "${NEXT_TAG}" --prerelease --draft --repo "${REPO}" --title "Release ${NEXT_TAG}" --notes "${RELEASE_NOTES}" --target "${GIT_SHA}"
    exit 0
  fi
fi

if [ "${UPLOAD_PRE_RELEASE}" = true ]; then
  printf "Uploading pre-release %s\n" "${NEXT_TAG}"
  if [ "${CIRRUS_CI:-}" = 'true' ] && [ "${CIRRUS_BRANCH:-}" = 'master' ]; then
    printf "Not on master in CIRRUS_CI, skipping pre-release upload\n"
    exit 0
  fi
  if [ "${CIRRUS_CI:-}" = 'true' ]; then
    LATEST_DRAFT_PRERELEASE=($(gh release list --limit 1 --repo "${REPO}" | jq -r '.[] | select(.draft == true and .prerelease == true) | .tag_name'))
    NEXT_TAG="${LATEST_DRAFT_PRERELEASE}"
  fi
  ls build/*.tar.gz
  # gh release upload "${NEXT_TAG}" build/*.tar.gz --repo "${REPO}" --clobber
  exit 0
fi

if [ "${DRY_RUN}" = true ]; then
  printf "Not pushing tags or creating releases as in dry run mode\n"
elif [ "${UPDATE_PRERELEASE_TO_RELEASED}" == 'true' ]; then
  gh release edit "${NEXT_TAG}" --title "Release ${NEXT_TAG}" --repo "${REPO}" --notes "${RELEASE_NOTES}" --draft=false --prerelease=false --target "${GIT_SHA}"
fi