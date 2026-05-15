#!/bin/sh
set -e

CONF=/etc/danted.conf

if [ "${LOG_LEVEL:-normal}" = "json" ]; then
    log() { printf '{"time":"%s","level":"info","message":"%s"}\n' "$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >&2; }
else
    log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
fi

. /scripts/lib/00-sysctl.sh
. /scripts/lib/01-network.sh
. /scripts/lib/02-users.sh
. /scripts/lib/03-config.sh
. /scripts/lib/04-tor.sh
. /scripts/lib/05-dante.sh
