#!/usr/bin/env bash
set -e

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`
source "$SELFDIR/../shared/library.sh"

TEMPDIR=

function cleanup()
{
	if [[ "$TEMPDIR" != "" ]]; then
		rm -rf "$TEMPDIR"
	fi
}

if [[ $# == 0 ]]; then
	echo "Usage: ./upload.sh <FILES>"
	echo "Uploads files to Amazon S3."
	exit 1
fi

if [[ "$IMAGE_VERSION" = "" ]]; then
	echo "ERROR: please set the IMAGE_VERSION environment variable."
	exit 1
fi

if [[ ! -e ~/.aws ]]; then
	echo "~/.aws doesn't exist; configuring one..."
	TEMPDIR=`mktemp -d /tmp/traveling-ruby.XXXXXXXX`
	docker run --rm -t -i --init \
		-v "$SELFDIR/internal:/system:ro" \
		-v "$TEMPDIR:/work" \
		-e "APP_UID=$(id -u)" \
		-e "APP_GID=$(id -u)" \
		"phusion/traveling-ruby-builder-x86_64:$IMAGE_VERSION" \
		/system/awsconfigure.sh
	mkdir ~/.aws
	cp -pR "$TEMPDIR/awscfg"/* ~/.aws/
	rm -rf "$TEMPDIR"
	TEMPDIR=
	echo
fi

MOUNTS=()
FILE_BASENAMES=()
DIR_BASENAMES=()
for F in "$@"; do
	BASENAME="`basename \"$F\"`"
	F="`absolute_path \"$F\"`"

	MOUNTS+=(-v "$F:/$BASENAME:ro")
	if [[ -f "$F" ]]; then
		FILE_BASENAMES+=("$BASENAME")
	else
		DIR_BASENAMES+=("$BASENAME")
	fi
done

header "Uploading `echo ${FILE_BASENAMES[@]}` to Amazon S3..."
AWSCFG="`echo ~/.aws`"

docker run --rm -t -i --init \
	"${MOUNTS[@]}" \
	-v "$AWSCFG:/awscfg:ro" \
	-v "$SELFDIR/internal:/system:ro" \
	"phusion/traveling-ruby-builder-x86_64:$IMAGE_VERSION" \
	/system/awsinit.sh \
	aws s3 cp "${FILE_BASENAMES[@]}" s3://traveling-ruby/releases/ --acl public-read

for DIR_BASENAME in "${DIR_BASENAMES[@]}"; do
	echo
	header "Uploading $DIR_BASENAME to Amazon S3..."
	docker run --rm -t -i --init \
		"${MOUNTS[@]}" \
		-v "$AWSCFG:/awscfg:ro" \
		-v "$SELFDIR/internal:/system:ro" \
		"phusion/traveling-ruby-builder-x86_64:$IMAGE_VERSION" \
		/system/awsinit.sh \
		aws s3 sync "$DIR_BASENAME" "s3://traveling-ruby/releases/$DIR_BASENAME/" --acl public-read --delete
done
