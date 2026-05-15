<div align="center">

# docker-socks5-proxy

[![Docker Pulls](https://img.shields.io/docker/pulls/lahiru98s/docker-socks5-proxy?style=flat-square&logo=docker&color=2496ed)](https://hub.docker.com/r/lahiru98s/docker-socks5-proxy)
[![Image Size](https://img.shields.io/docker/image-size/lahiru98s/docker-socks5-proxy/latest?style=flat-square&logo=docker&color=2496ed)](https://hub.docker.com/r/lahiru98s/docker-socks5-proxy)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)
[![Alpine](https://img.shields.io/badge/Alpine-3.21-0d597f?style=flat-square&logo=alpinelinux)](https://alpinelinux.org/)

Lightweight SOCKS5 proxy server built on [Dante](https://www.inet.no/dante/) and Alpine Linux. Single ~15 MB image, zero runtime dependencies, fully configurable via environment variables.

[Features](#features) [Quick start](#quick-start) [Configuration](#configuration) [Authentication](#authentication) [Access control](#access-control) [Traffic routing](#traffic-routing) [Advanced](#advanced)

</div>

## Features

- **SOCKS5** -- Full TCP support with optional UDP ASSOCIATE via Dante
- **Flexible auth** -- Open proxy, single user, or multi-user via env vars or file
- **Source IP filtering** -- Restrict inbound connections to specific CIDRs
- **Destination filtering** -- Block outbound access by IP, CIDR, or domain name
- **Domain allowlist mode** -- Lock proxy to specific destination domains only
- **Tor routing** -- Route all traffic through Tor with a single env var
- **Upstream proxy chaining** -- Chain through one or more upstream SOCKS5 proxies
- **IPv6 ready** -- Optional dual-stack internal listener
- **DNS control** -- Override the container resolver to prevent leaks
- **JSON logging** -- Structured log output for log aggregators (Loki, ELK, etc.)
- **Graceful shutdown** -- Configurable drain timeout for active connections on stop
- **Performance tuned** -- Kernel TCP tuning, file descriptor limits, optimized timeouts
- **Health check** -- Built-in `HEALTHCHECK` for container orchestration
- **Hot reload** -- Send `SIGHUP` to reload config without restarting

## Quick start

### Use the prebuilt image

```bash
docker run -d --name socks5-server --restart unless-stopped -p 54178:1080 lahiru98s/docker-socks5-proxy:latest
```

Or with authentication:

```bash
docker run -d --name socks5-server --restart unless-stopped \
  -p 54178:1080 \
  -e PROXY_USER=alice \
  -e PROXY_PASS=secret \
  lahiru98s/docker-socks5-proxy:latest
```

### Compose (prebuilt)

```bash
curl -O https://raw.githubusercontent.com/nooblk-98/docker-socks5-proxy/main/docker-compose.prebuilt.yml
docker compose -f docker-compose.prebuilt.yml up -d
```

### Build from source

```bash
git clone https://github.com/nooblk-98/docker-socks5-proxy.git
cd docker-socks5-proxy
cp .env.example .env
docker compose up -d --build
```

The proxy listens on port `54178` by default (configurable via `SOCKS5_PORT`).

### Verify it works

```bash
curl --socks5 127.0.0.1:54178 --max-time 10 https://httpbin.org/ip
```

## Configuration

All configuration is done through environment variables. Copy `.env.example` to `.env` and customize:

| Variable | Default | Description |
|---|---|---|
| `SOCKS5_PORT` | `54178` | Host port mapped to the SOCKS5 listener |
| `PROXY_USER` | _(empty)_ | Single username (leave empty for open proxy) |
| `PROXY_PASS` | _(empty)_ | Single user password |
| `PROXY_USERS` | _(empty)_ | Comma-separated `user:pass` pairs (overrides single user) |
| `ALLOWED_CIDR` | _(empty)_ | Comma-separated source CIDRs permitted to connect |
| `ALLOWED_DOMAINS` | _(empty)_ | Comma-separated destination domains to allow (blocks all others) |
| `BLOCKED_DESTINATIONS` | _(empty)_ | Comma-separated destination IPs/CIDRs to block outbound |
| `BLOCKED_DOMAINS` | _(empty)_ | Comma-separated destination domains to block (resolved at startup) |
| `UDP_ENABLED` | `false` | Enable SOCKS5 UDP ASSOCIATE |
| `IPV6_ENABLED` | `false` | Add an IPv6 internal listener (`:: 1080`) |
| `DNS_SERVER` | _(empty)_ | Override container DNS resolver (e.g. `1.1.1.1`) |
| `TIMEOUT_CONNECT` | `30` | TCP connect timeout in seconds |
| `TIMEOUT_NEGOTIATE` | `30` | SOCKS5 negotiation timeout in seconds |
| `TIMEOUT_IO` | `86400` | Idle session timeout in seconds |
| `TOR_ENABLED` | `false` | Route all outbound traffic through Tor |
| `UPSTREAM_PROXY` | _(empty)_ | Comma-separated `socks5://user:pass@host:port` URLs to chain through |
| `LOG_LEVEL` | `normal` | `normal` (per-connection logs), `quiet` (errors only), or `json` (structured JSON) |
| `DRAIN_TIMEOUT` | `5` | Seconds to wait for active connections to finish before force-killing on stop |

## Authentication

The proxy supports multiple authentication modes.

**Open proxy** -- Leave `PROXY_USER` and `PROXY_PASS` unset (the default).

**Single user:**

```env
PROXY_USER=alice
PROXY_PASS=secret
```

**Multiple users via environment variable:**

```env
PROXY_USERS=alice:secret,bob:hunter2
```

**Multiple users via file:** Create a `users.txt` with one `user:pass` per line:

```
# Proxy users
alice:secret
bob:hunter2
```

Mount it into the container:

```yaml
services:
  socks5:
    image: lahiru98s/docker-socks5-proxy:latest
    volumes:
      - ./users.txt:/etc/proxy-users.txt:ro
```

> [!TIP]
> `PROXY_USERS` takes precedence over `PROXY_USER`/`PROXY_PASS`. The file mount at `/etc/proxy-users.txt` takes precedence over both.

## Access control

### Source IP allowlist

Restrict which clients can connect to the proxy by source IP or CIDR. All other clients are blocked.

```env
ALLOWED_CIDR=203.0.113.0/24,198.51.100.5/32
```

### Destination IP block

Block outbound access to specific IPs or subnets. Useful for preventing access to internal networks (RFC 1918).

```env
BLOCKED_DESTINATIONS=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
```

### Domain block

Block outbound access to specific domains. Domains are resolved to their current IPs at startup.

```env
BLOCKED_DOMAINS=malware.example.com,spyware.example.org
```

> [!NOTE]
> Domain resolution happens at container startup. To pick up IP changes, restart or send `SIGHUP` to the container.

### Domain allowlist (restrictive mode)

Lock the proxy to only allow traffic to specific destination domains. All other destinations are blocked.

```env
ALLOWED_DOMAINS=api.example.com,github.com
```

This is useful for creating a tightly scoped proxy that only permits access to known endpoints.

## Traffic routing

### Tor routing

Route all proxied traffic through the Tor network. The Tor daemon starts automatically inside the container.

```env
TOR_ENABLED=true
```

Dante forwards all connections to Tor's local SOCKS5 port (`9050`).

> [!NOTE]
> The first connection after startup may be slow while Tor builds its circuits.

### Upstream proxy chaining

Chain traffic through one or more upstream SOCKS5 proxies. Each upstream is specified as a SOCKS5 URL.

```env
# Single upstream proxy
UPSTREAM_PROXY=socks5://10.0.0.1:1080

# Multiple upstream proxies (comma-separated)
UPSTREAM_PROXY=socks5://proxy1:1080,socks5://proxy2:1080

# With authentication
UPSTREAM_PROXY=socks5://user:pass@proxy1:1080
```

Each upstream generates a Dante `route` directive, chaining traffic through the specified proxy. When multiple upstreams are provided, the first to become available is used. The upstream can reference another Dante instance, a Tor SOCKS port, or any SOCKS5-compatible proxy.

> [!TIP]
> You can build multi-hop chains by deploying multiple instances: proxy A routes through proxy B which routes through proxy C.

## Advanced

### Logging modes

The `LOG_LEVEL` variable supports three modes:

```env
# Normal -- per-connection logs (default)
LOG_LEVEL=normal

# Quiet -- errors only, for high-throughput deployments
LOG_LEVEL=quiet

# JSON -- structured output for log aggregators (Loki, ELK, Datadog)
LOG_LEVEL=json
```

JSON mode produces lines like:

```json
{"time":"2026-05-15T17:42:45+00:00","level":"info","pid":29,"connection":"pass(1)","event":"tcp/connect","message":"..."}
```

### UDP support

Enable SOCKS5 UDP ASSOCIATE for UDP-based protocols (DNS over SOCKS, etc.):

```env
UDP_ENABLED=true
```

### IPv6

Add an IPv6 internal listener on `[::]:1080`:

```env
IPV6_ENABLED=true
```

> [!NOTE]
> Docker's default network is IPv4-only. To use IPv6, enable `enable_ipv6` in your Docker daemon configuration.

### Custom DNS

Override the container DNS resolver to control which nameserver is used for outbound DNS queries:

```env
DNS_SERVER=1.1.1.1
```

### Graceful shutdown

When the container receives a `SIGTERM` (e.g. `docker stop`), Dante stops accepting new connections and waits for active sessions to complete. The `DRAIN_TIMEOUT` variable controls how long to wait before forcefully terminating remaining connections:

```env
DRAIN_TIMEOUT=10
```

The default is `5` seconds. Docker's `stop_grace_period` should be set at least a few seconds higher than `DRAIN_TIMEOUT`.

### Graceful config reload

Apply configuration changes without restarting the container:

```bash
docker kill --signal=HUP socks5-server
```

This re-generates the Dante configuration from current environment variables and tells Dante to reload.

## Performance

The container applies several kernel-level optimizations at startup:

- `net.core.somaxconn` -- Increased listen backlog (32768)
- `net.core.rmem_max` / `net.core.wmem_max` -- Larger socket buffers (16 MB)
- `net.ipv4.tcp_fin_timeout` -- Faster connection teardown (15 s)
- `net.ipv4.tcp_keepalive_time` -- Longer keepalive interval (300 s)

File descriptor limits are set to `65536` (soft and hard) in the Docker Compose files.
