IFACE=$(ip route | awk '/default/ {print $5; exit}')
if [ -z "$IFACE" ]; then
    log "ERROR: Could not detect network interface"
    exit 1
fi
log "INFO: Outbound interface: $IFACE"

if [ -n "${DNS_SERVER:-}" ]; then
    log "INFO: Overriding DNS with $DNS_SERVER"
    printf 'nameserver %s\n' "$DNS_SERVER" > /etc/resolv.conf
fi
