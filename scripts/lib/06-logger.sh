#!/bin/sh
# JSON log formatter — reads Dante log lines from stdin, outputs JSON to stdout
# Usage: cat /path/to/log | /scripts/lib/06-logger.sh

while IFS= read -r line; do
    [ -z "$line" ] && continue

    _level="info"
    case "$line" in
        *'error:'*) _level="error" ;;
        *'warn:'*)  _level="warn"  ;;
        *'debug:'*) _level="debug" ;;
    esac

    _pid=$(printf '%s' "$line" | sed -n 's/.*sockd\[\([0-9]*\)\].*/\1/p')
    [ -z "$_pid" ] && _pid="0"

    _conn=$(printf '%s' "$line" | sed -n 's/.*\(pass\|block\)(\([0-9]*\)).*/\1(\2)/p')

    _event=$(printf '%s' "$line" | sed -n 's/.*\(tcp\/[a-z]*\).*/\1/p')

    _msg=$(printf '%s' "$line" | sed 's/"/\\"/g')
    _ts=$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')

    printf '{"time":"%s","level":"%s","pid":%s,"connection":"%s","event":"%s","message":"%s"}\n' \
        "$_ts" "$_level" "$_pid" "$_conn" "$_event" "$_msg"
done
