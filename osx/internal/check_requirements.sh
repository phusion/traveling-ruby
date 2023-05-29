#!/bin/bash

set -e

XCODEPATH=$(xcode-select -p)
if [[ "$XCODEPATH" == "/Library/Developer/CommandLineTools" ]]; then
  XCODEPATH="$XCODEPATH/SDKs/MacOSX.sdk"
elif [[ "$XCODEPATH" == "/Applications/Xcode.app/Contents/Developer" ]]; then
  XCODEPATH="$XCODEPATH/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
elif [[ "$XCODEPATH" == "/Applications/Xcode_14.2.app/Contents/Developer" ]]; then
  XCODEPATH="$XCODEPATH/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
else
  echo "*** ERROR: unknown developer path \"$XCODEPATH\""
  exit 1
fi

if [[ -e /usr/local/include ]]; then
	echo "*** ERROR: /usr/local/include exists, which may pollute the" \
		"build environment. Please temporarily rename it away:" >&2
	echo >&2
	echo "    rake stash_conflicting_paths" >&2
	exit 1
fi

if [[ -e /usr/local/lib ]]; then
	echo "*** ERROR: /usr/local/lib exists, which may pollute the" \
		"build environment. Please temporarily rename it away:" >&2
	echo >&2
	echo "    rake stash_conflicting_paths" >&2
	exit 1
fi
