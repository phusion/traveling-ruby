#!/usr/bin/env bash
set -e
cp -r /awscfg /root/.aws
chown -R root: /root/.aws
exec "$@"
