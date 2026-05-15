DRAIN_SLEEP="${DRAIN_TIMEOUT:-5}"

if [ "${LOG_LEVEL:-normal}" = "json" ]; then
    LOG_PIPE=/tmp/dante-logpipe
    rm -f "$LOG_PIPE"
    mkfifo "$LOG_PIPE"
    /scripts/lib/06-logger.sh < "$LOG_PIPE" &
    LOGGER_PID=$!
    sockd -f "$CONF" >/dev/null 2>"$LOG_PIPE" &
    SOCKD_PID=$!
else
    sockd -f "$CONF" >/dev/null 2>&1 &
    SOCKD_PID=$!
fi

sleep 1
if ! kill -0 "$SOCKD_PID" 2>/dev/null; then
    log "ERROR: Dante failed to start — check the config at $CONF"
    exit 1
fi
log "INFO: Dante started (PID $SOCKD_PID)"

_reload_config() {
    log "INFO: Reloading Dante config..."
    . /scripts/lib/03-config.sh
    kill -HUP "$SOCKD_PID" 2>/dev/null
}

_shutdown() {
    log "INFO: Shutting down... draining connections for ${DRAIN_SLEEP}s"
    kill -TERM "$SOCKD_PID" 2>/dev/null

    _elapsed=0
    while [ "$_elapsed" -lt "$DRAIN_SLEEP" ]; do
        if ! kill -0 "$SOCKD_PID" 2>/dev/null; then
            break
        fi
        sleep 1
        _elapsed=$((_elapsed + 1))
    done

    if kill -0 "$SOCKD_PID" 2>/dev/null; then
        log "WARN: Drain timeout ($DRAIN_SLEEP s) — force killing PID $SOCKD_PID"
        kill -KILL "$SOCKD_PID" 2>/dev/null
    fi

    [ -n "$LOGGER_PID" ] && kill -TERM "$LOGGER_PID" 2>/dev/null || true
    rm -f /tmp/dante-logpipe 2>/dev/null || true

    wait "$SOCKD_PID" 2>/dev/null || true
    log "INFO: Dante exited. Goodbye."
    exit 0
}

trap '_reload_config' HUP
trap '_shutdown' TERM INT

while kill -0 "$SOCKD_PID" 2>/dev/null; do
    wait "$SOCKD_PID" 2>/dev/null || true
done
