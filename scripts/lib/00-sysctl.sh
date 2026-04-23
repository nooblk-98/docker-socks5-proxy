_sysctl() { sysctl -w "$1" >/dev/null 2>&1 || true; }

_sysctl net.core.somaxconn=32768
_sysctl net.core.rmem_max=16777216
_sysctl net.core.wmem_max=16777216
_sysctl net.ipv4.tcp_rmem="4096 87380 16777216"
_sysctl net.ipv4.tcp_wmem="4096 87380 16777216"
_sysctl net.ipv4.tcp_tw_reuse=1
_sysctl net.ipv4.tcp_fin_timeout=15
_sysctl net.ipv4.tcp_keepalive_time=300
_sysctl net.ipv4.tcp_keepalive_intvl=30
_sysctl net.ipv4.tcp_keepalive_probes=5
