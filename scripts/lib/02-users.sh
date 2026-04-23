AUTH_ENABLED=false
PASSWD_DATA=""

provision_user() {
    local user="$1" pass="$2"
    [ -z "$user" ] && return
    [ -z "$pass" ] && return
    if ! id "$user" >/dev/null 2>&1; then
        useradd -M -s /usr/sbin/nologin "$user"
    fi
    PASSWD_DATA="${PASSWD_DATA}${user}:${pass}
"
    log "INFO: Provisioned user: $user"
}

if [ -f "/etc/proxy-users.txt" ]; then
    log "INFO: Auth mode: multi-user (file)"
    AUTH_ENABLED=true
    while IFS= read -r line; do
        case "$line" in '#'*|'') continue ;; esac
        _u_raw="${line%%:*}"
        _p="${line#*:}"
        # Remove whitespace from username without forking tr
        _u=""
        _s_ifs="$IFS"; IFS="
"
        for _part in $_u_raw; do _u="${_u}${_part}"; done
        IFS="$_s_ifs"
        [ -z "$_u" ] && continue
        provision_user "$_u" "$_p"
    done < /etc/proxy-users.txt
elif [ -n "${PROXY_USERS:-}" ]; then
    log "INFO: Auth mode: multi-user (env)"
    AUTH_ENABLED=true
    _save_ifs="$IFS"; IFS=','
    for pair in $PROXY_USERS; do
        IFS="$_save_ifs"
        _u="${pair%%:*}"
        _p="${pair#*:}"
        provision_user "$_u" "$_p"
        IFS=','
    done
    IFS="$_save_ifs"
elif [ -n "${PROXY_USER:-}" ] && [ -n "${PROXY_PASS:-}" ]; then
    log "INFO: Auth mode: single user ($PROXY_USER)"
    AUTH_ENABLED=true
    provision_user "$PROXY_USER" "$PROXY_PASS"
else
    log "INFO: Auth mode: none (open proxy)"
fi

if [ -n "$PASSWD_DATA" ]; then
    printf '%s' "$PASSWD_DATA" | chpasswd
fi
