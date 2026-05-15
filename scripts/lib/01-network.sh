IFACE=$(awk '$2 == "00000000" {print $1; exit}' /proc/net/route)
if [ -z "$IFACE" ]; then
    log "ERROR: Could not detect network interface"
    exit 1
fi
log "INFO: Outbound interface: $IFACE"

if [ -n "${DNS_SERVER:-}" ]; then
    log "INFO: Overriding DNS with $DNS_SERVER"
    # Prepend custom DNS, preserving non-nameserver lines as fallback
    {
        printf 'nameserver %s\n' "$DNS_SERVER"
        grep -v '^nameserver' /etc/resolv.conf 2>/dev/null || true
    } > /etc/resolv.conf
fi
