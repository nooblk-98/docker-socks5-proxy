sockd -f "$CONF" &
SOCKD_PID=$!

# Verify Dante started successfully
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

trap '_reload_config' HUP
trap 'log "INFO: Shutting down..."; kill -TERM "$SOCKD_PID" 2>/dev/null; wait "$SOCKD_PID" 2>/dev/null; exit 0' TERM INT

# Keep waiting as long as Dante is alive.  When SIGHUP interrupts wait(),
# the trap handler runs and we loop back.  When Dante exits (TERM/INT or
# crash), the loop ends and the script follows the TERM/INT trap above.
while kill -0 "$SOCKD_PID" 2>/dev/null; do
    wait "$SOCKD_PID" 2>/dev/null || true
done
