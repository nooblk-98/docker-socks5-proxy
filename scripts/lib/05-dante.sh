sockd -f "$CONF" &
SOCKD_PID=$!
log "INFO: Dante started (PID $SOCKD_PID)"

trap 'log "INFO: Reloading Dante config..."; kill -HUP "$SOCKD_PID" 2>/dev/null' HUP
trap 'log "INFO: Shutting down..."; kill -TERM "$SOCKD_PID" 2>/dev/null; wait "$SOCKD_PID" 2>/dev/null; exit 0' TERM INT

wait "$SOCKD_PID"
