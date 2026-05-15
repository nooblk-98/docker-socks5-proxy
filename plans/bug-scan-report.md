# Bug Scan Report — docker-socks5-proxy

**Date:** 2026-05-15  
**Scope:** All source files in the repository  
**Files reviewed:** Dockerfile, docker-compose.yml, docker-compose.prebuilt.yml, .env.example, .dockerignore, .gitignore, config/danted.conf, scripts/entrypoint.sh, scripts/lib/*.sh, .github/workflows/docker-publish.yml, README.md

---

## 🔴 Critical Bugs

### 1. TLS config referenced but NOT implemented

**Severity:** Critical  
**Files:** [`.env.example`](.env.example:41-49), [`docker-compose.yml`](docker-compose.yml)  
**Description:** The `.env.example` file documents three TLS-related variables — `TLS_ENABLED`, `TLS_PORT`, and `TLS_CERT` — but there is **zero TLS implementation** anywhere in the codebase:
- No TLS/SSL packages installed in the [`Dockerfile`](Dockerfile)
- No TLS config generated in [`03-config.sh`](scripts/lib/03-config.sh)
- No TLS-related env vars passed in the [`docker-compose.yml`](docker-compose.yml) `environment` block
- No `stunnel` or `socat` wrapper in [`entrypoint.sh`](scripts/entrypoint.sh)

**Impact:** Users who read `.env.example` will expect TLS to work and will set these variables, but they will have no effect. This is a misleading documentation/feature bug.

**Fix:** Either implement TLS (e.g., via stunnel on port 1443 proxying to Dante on 1080) or remove the TLS variables from `.env.example`.

---

### 2. SIGHUP hot reload does NOT regenerate config

**Severity:** Critical  
**Files:** [`scripts/lib/05-dante.sh`](scripts/lib/05-dante.sh:5), [`README.md`](README.md:178-182)  
**Description:** The README advertises hot reload: *"Send SIGHUP to reload config without restarting"*. However, the HUP trap in `05-dante.sh` only runs:

```sh
kill -HUP "$SOCKD_PID"
```

It does **not**:
- Re-source environment variables
- Re-run the config generation logic from [`03-config.sh`](scripts/lib/03-config.sh)
- Reprovision users from [`02-users.sh`](scripts/lib/02-users.sh)

**Impact:** Changing any environment variable and sending SIGHUP will have **zero effect** — the on-disk config at `/etc/danted.conf` remains unchanged, and Dante reloads the same config it already had.

**Fix:** The HUP handler should re-source the config generation pipeline before sending HUP to Dante.

---

### 3. Dante startup failure goes undetected (silent failure)

**Severity:** Critical  
**File:** [`scripts/lib/05-dante.sh`](scripts/lib/05-dante.sh:1-3)  
**Description:** Dante is started as a background process with `&`:

```sh
sockd -f "$CONF" &
SOCKD_PID=$!
```

Because it runs in the background, `set -e` at the top of `entrypoint.sh` cannot catch a startup failure. If `sockd` exits immediately (e.g., invalid config syntax, port already in use), then:

- `SOCKD_PID` refers to a dead process
- The `wait "$SOCKD_PID"` on line 8 hangs indefinitely
- The `HEALTHCHECK` in the Dockerfile only checks if port 1080 is open (via nc), so it may pass if a leftover process or another service holds the port
- The container appears healthy but serves NO traffic

**Impact:** Container starts successfully but Dante is dead. No error is logged or surfaced. This is a silent failure.

**Fix:** Check that `sockd` is still alive shortly after starting, or run it in the foreground and use a proper process supervisor pattern.

---

## 🟡 Medium Bugs

### 4. docker-compose `sysctls` require elevated privileges

**Severity:** Medium  
**Files:** [`docker-compose.yml`](docker-compose.yml:30-33), [`docker-compose.prebuilt.yml`](docker-compose.prebuilt.yml:30-33), [`scripts/lib/00-sysctl.sh`](scripts/lib/00-sysctl.sh:1)  
**Description:** Both compose files set kernel parameters via the `sysctls` block:

```yaml
sysctls:
  net.core.somaxconn: 32768
  net.ipv4.tcp_fin_timeout: 15
  net.ipv4.tcp_keepalive_time: 300
```

Docker requires `privileged: true` or at minimum `cap_add: SYS_ADMIN` to set these sysctls. Neither compose file includes either. Simultaneously, [`00-sysctl.sh`](scripts/lib/00-sysctl.sh) also tries to set these same values via `sysctl -w`, masked with `|| true`.

**Impact:** On most Docker configurations (without privileged mode), the `sysctls` block in compose will either fail silently or produce a warning, and the `00-sysctl.sh` script's `sysctl -w` calls will fail silently because they run inside an unprivileged container. The performance tuning the project advertises is **never actually applied**.

**Fix:** Either add `privileged: true` or `cap_add: SYS_ADMIN` to the compose files, or add a warning log in `00-sysctl.sh` when `sysctl -w` fails.

---

### 5. Redundant Tor readiness check

**Severity:** Medium  
**File:** [`scripts/lib/04-tor.sh`](scripts/lib/04-tor.sh:11-22)  
**Description:** The Tor readiness check has two sequential checks:

1. **Lines 12-16:** A while loop that polls port 9050 up to 30 times (break on success)
2. **Lines 18-22:** A second `nc` check that repeats the exact same test

If the while loop succeeded (port is open), the second check is redundant. If the while loop timed out (port never opened), the second check will also fail.

**Impact:** Unnecessary code duplication. Minor but wastes startup time.

**Fix:** Remove the redundant check on lines 18-22. The while loop's result is sufficient.

---

### 6. Destructive `/etc/resolv.conf` overwrite

**Severity:** Medium  
**File:** [`scripts/lib/01-network.sh`](scripts/lib/01-network.sh:8-11)  
**Description:** When `DNS_SERVER` is set, the script overwrites the entire `/etc/resolv.conf`:

```sh
printf 'nameserver %s\n' "$DNS_SERVER" > /etc/resolv.conf
```

This replaces any existing resolvers with a single nameserver. In Alpine Docker containers, `/etc/resolv.conf` is typically a bind-mounted file from the host. Overwriting it means the container can no longer resolve hostnames if the specified DNS server becomes unreachable.

**Impact:** Single point of failure for DNS resolution. No fallback resolver.

**Fix:** Prepend the custom DNS server to `/etc/resolv.conf` rather than replacing it entirely.

---

## 🟢 Minor / Quality Issues

### 7. HEALTHCHECK only checks port liveness, not protocol correctness

**Severity:** Minor  
**File:** [`Dockerfile`](Dockerfile:20-21)  
**Description:** The HEALTHCHECK uses:

```dockerfile
CMD nc -w 1 127.0.0.1 1080 </dev/null || exit 1
```

This only confirms something is listening on port 1080. It does not verify that Dante responds correctly to a SOCKS5 handshake (which starts with `0x05`).

**Impact:** Another process (or a hung Dante) could hold port 1080, and the container would still pass the health check.

**Fix:** Use a proper SOCKS5 health check that sends a SOCKS5 handshake and validates the response.

---

### 8. Container runs as root

**Severity:** Minor  
**File:** [`Dockerfile`](Dockerfile)  
**Description:** No `USER` directive is used. The entire container runs as root, including the main process (Dante's `sockd`). While Dante does drop privileges for client connections via `user.notprivileged: nobody`, the main process retains root capabilities.

**Impact:** If an attacker compromises the container through Dante, they gain root access inside the container. This is a defense-in-depth concern.

**Fix:** Add a `USER` directive or use a non-root entrypoint wrapper that drops privileges.

---

### 9. Hardcoded container name prevents multi-instance deployments

**Severity:** Minor  
**File:** [`docker-compose.yml`](docker-compose.yml:4), [`docker-compose.prebuilt.yml`](docker-compose.prebuilt.yml:4)  
**Description:** Both compose files hardcode `container_name: socks5-server`. This prevents running multiple instances of the service on the same Docker host.

**Impact:** Users can't scale up or run separate configurations concurrently without editing the compose files.

**Fix:** Remove the `container_name` directive and let Docker auto-generate names, or make it configurable via an environment variable.

---

## ✅ Verified as Correct

The following aspects of the codebase were checked and are **bug-free**:

- **Shell script sourcing order** in `entrypoint.sh` — correct dependency order (sysctl → network → users → config → tor → dante)
- **IFS handling** in `02-users.sh` and `03-config.sh` — correctly saves and restores `IFS` around comma-split loops
- **Signal handling** in `05-dante.sh` — TERM/INT propagate to child process properly
- **Config generation** in `03-config.sh` — correctly handles all environment variable combinations
- **User provisioning** in `02-users.sh` — properly handles file-based, env-based, single-user, and open-proxy modes
- **Build pipeline** in `.github/workflows/docker-publish.yml` — uses current action versions, signs images, includes SBOM/provenance
- **`.dockerignore`** — excludes all files unnecessary for the build context
- **Multi-arch build** — correctly targets `linux/amd64` and `linux/arm64`

---

## Summary

| Severity | Count | Key Issues |
|----------|-------|------------|
| 🔴 Critical | 3 | TLS phantom feature, broken hot reload, silent Dante failure |
| 🟡 Medium | 3 | Missing compose privileges, redundant Tor check, destructive DNS overwrite |
| 🟢 Minor | 3 | Shallow HEALTHCHECK, root container, hardcoded container name |
