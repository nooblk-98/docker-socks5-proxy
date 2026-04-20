#!/bin/sh
set -e

CONF=/etc/danted.conf

# Detect the outbound network interface
IFACE=$(ip route | awk '/default/ {print $5; exit}')
if [ -z "$IFACE" ]; then
    echo "ERROR: Could not detect network interface" >&2
    exit 1
fi

# Patch the external interface in the config
sed -i "s/^external:.*/external: $IFACE/" "$CONF"

# If credentials are provided, enable username/password auth
if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASS" ]; then
    echo "Auth mode: username/password ($PROXY_USER)"

    # Create system user for dante auth (no home, no shell)
    if ! id "$PROXY_USER" >/dev/null 2>&1; then
        useradd -M -s /usr/sbin/nologin "$PROXY_USER"
    fi
    echo "$PROXY_USER:$PROXY_PASS" | chpasswd

    sed -i \
        -e 's/^clientmethod:.*/clientmethod: none/' \
        -e 's/^socksmethod:.*/socksmethod: username/' \
        "$CONF"
else
    echo "Auth mode: none (open proxy)"
fi

touch /var/log/danted.log
exec sockd -f "$CONF"
