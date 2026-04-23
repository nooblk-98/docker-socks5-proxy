#!/bin/sh
set -e

CONF=/etc/danted.conf
log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

. /scripts/lib/00-sysctl.sh
. /scripts/lib/01-network.sh
. /scripts/lib/02-users.sh
. /scripts/lib/03-config.sh
. /scripts/lib/04-tor.sh
. /scripts/lib/05-dante.sh
