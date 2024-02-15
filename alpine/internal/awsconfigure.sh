#!/usr/bin/env bash
set -e
/hbb/bin/setuser app aws configure
cp -dpR ~app/.aws /work/awscfg
chown "$APP_UID:$APP_GID" /work/awscfg
