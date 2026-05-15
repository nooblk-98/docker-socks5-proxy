<div align="center">

# docker-socks5-proxy

[![Docker Pulls](https://img.shields.io/docker/pulls/lahiru98s/docker-socks5-proxy?style=flat-square&logo=docker&color=2496ed)](https://hub.docker.com/r/lahiru98s/docker-socks5-proxy)
[![Image Size](https://img.shields.io/docker/image-size/lahiru98s/docker-socks5-proxy/latest?style=flat-square&logo=docker&color=2496ed)](https://hub.docker.com/r/lahiru98s/docker-socks5-proxy)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)
[![Alpine](https://img.shields.io/badge/Alpine-3.21-0d597f?style=flat-square&logo=alpinelinux)](https://alpinelinux.org/)

Lightweight SOCKS5 proxy server built on [Dante](https://www.inet.no/dante/) and Alpine Linux. Single ~15 MB image, zero runtime dependencies, fully configurable via environment variables.

[Features](#features) • [Quick start](#quick-start) • [Configuration](#configuration) • [Authentication](#authentication) • [Access control](#access-control)

</div>

## Features

- **SOCKS5** — Full TCP support with optional UDP ASSOCIATE via Dante
- **Flexible auth** — Open proxy, single user, or multi-user via env/file
- **IP allowlisting** — Restrict inbound connections to specific CIDRs
- **Destination filtering** — Block outbound access to IPs or subnets
- **Tor routing** — Route all traffic through the Tor network with one env var
- **IPv6 ready** — Optional dual-stack internal listener
- **DNS control** — Override the container resolver to prevent leaks
- **Performance tuned** — Kernel TCP tuning, fd limits, and optimized timeouts
- **Health check** — Built-in `HEALTHCHECK` for container orchestration
- **Hot reload** — Send `SIGHUP` to reload config without restarting

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

## Configuration

All configuration is done through environment variables. Copy `.env.example` to `.env` and customize:

| Variable | Default | Description |
|---|---|---|
| `SOCKS5_PORT` | `54178` | Host port mapped to the SOCKS5 listener |
| `PROXY_USER` | _(empty)_ | Single username (leave empty for open proxy) |
| `PROXY_PASS` | _(empty)_ | Single user password |
| `PROXY_USERS` | _(empty)_ | Comma-separated `user:pass` pairs (overrides single user) |
| `ALLOWED_CIDR` | _(empty)_ | Comma-separated source CIDRs permitted to connect |
| `BLOCKED_DESTINATIONS` | _(empty)_ | Comma-separated destination IPs/CIDRs to block outbound |
| `UDP_ENABLED` | `false` | Enable SOCKS5 UDP ASSOCIATE |
| `IPV6_ENABLED` | `false` | Add an IPv6 internal listener (`:: 1080`) |
| `DNS_SERVER` | _(empty)_ | Override container DNS resolver (e.g. `1.1.1.1`) |
| `TIMEOUT_CONNECT` | `30` | TCP connect timeout in seconds |
| `TIMEOUT_NEGOTIATE` | `30` | SOCKS5 negotiation timeout in seconds |
| `TIMEOUT_IO` | `86400` | Idle session timeout in seconds |
| `TOR_ENABLED` | `false` | Route all outbound traffic through Tor |
| `LOG_LEVEL` | `normal` | Set to `quiet` to suppress connect/disconnect logs |

## Authentication

The proxy supports multiple authentication modes.

**Open proxy** — Leave `PROXY_USER` and `PROXY_PASS` unset (the default).

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
volumes:
  - ./users.txt:/etc/proxy-users.txt:ro
```

## Access control

### IP allowlist

Restrict inbound connections to specific source CIDRs. All other clients are blocked.

```env
ALLOWED_CIDR=203.0.113.0/24,198.51.100.5/32
```

### Destination filtering

Block outbound access to specific IPs or subnets — useful for preventing access to internal networks.

```env
BLOCKED_DESTINATIONS=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
```

## Tor routing

Route all proxied traffic through the Tor network with a single variable:

```env
TOR_ENABLED=true
```

Dante forwards all connections to Tor's local SOCKS5 port (`9050`). The Tor daemon starts automatically inside the container.

> The first connection after startup may be slow while Tor builds its circuits.

## Advanced

### UDP support

```env
UDP_ENABLED=true
```

### IPv6

```env
IPV6_ENABLED=true
```

> Docker's default network is IPv4-only. To use IPv6, enable `enable_ipv6` in your Docker daemon configuration.

### Custom DNS

```env
DNS_SERVER=1.1.1.1
```

### Quiet log mode

For high-throughput deployments, suppress per-connection log entries:

```env
LOG_LEVEL=quiet
```

### Graceful config reload

```bash
docker kill --signal=HUP socks5-server
```
