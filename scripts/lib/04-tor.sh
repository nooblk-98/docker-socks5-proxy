if [ "${TOR_ENABLED:-false}" = "true" ]; then
    log "INFO: Starting Tor daemon..."
    mkdir -p /tmp/tor-data
    chmod 700 /tmp/tor-data
    tor --RunAsDaemon 1 \
        --SocksPort 9050 \
        --DataDirectory /tmp/tor-data \
        --Log "notice file /tmp/tor-data/notices.log"

    log "INFO: Waiting for Tor to be ready..."
    _i=0
    while [ "$_i" -lt 30 ]; do
        nc -w 1 127.0.0.1 9050 </dev/null 2>/dev/null && break
        sleep 1
        _i=$((_i + 1))
    done

    if nc -w 1 127.0.0.1 9050 </dev/null 2>/dev/null; then
        log "INFO: Tor ready on 127.0.0.1:9050"
    else
        log "WARN: Tor did not become ready in time — continuing anyway"
    fi
fi
