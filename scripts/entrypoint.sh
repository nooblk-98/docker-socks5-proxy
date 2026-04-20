#!/bin/sh
set -e

CONF=/etc/danted.conf

# Detect the outbound network interface
IFACE=$(ip route | awk '/default/ {print $5; exit}')
if [ -z "$IFACE" ]; then
    echo "ERROR: Could not detect network interface" >&2
    exit 1
fi

echo "Outbound interface: $IFACE"
sed -i "s/^external:.*/external: $IFACE/" "$CONF"

# If credentials are provided, enable username/password auth
if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASS" ]; then
    echo "Auth mode: username/password ($PROXY_USER)"

    if ! id "$PROXY_USER" >/dev/null 2>&1; then
        useradd -M -s /usr/sbin/nologin "$PROXY_USER"
    fi
    echo "$PROXY_USER:$PROXY_PASS" | chpasswd

    sed -i 's/^socksmethod:.*/socksmethod: username/' "$CONF"
else
    echo "Auth mode: none (open proxy)"
fi

exec sockd -f "$CONF"
