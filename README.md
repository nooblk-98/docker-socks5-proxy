# docker-socks5-proxy

A production-ready, lightweight SOCKS5 proxy server built on [Dante](https://www.inet.no/dante/) and Alpine Linux. Single ~15MB image, zero runtime dependencies, fully configurable via environment variables.

[![Docker Hub](https://img.shields.io/docker/pulls/lahiru98s/docker-socks5-proxy?style=flat-square&logo=docker)](https://hub.docker.com/r/lahiru98s/docker-socks5-proxy)
[![Image Size](https://img.shields.io/docker/image-size/lahiru98s/docker-socks5-proxy/latest?style=flat-square)](https://hub.docker.com/r/lahiru98s/docker-socks5-proxy)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

---

## Features

| Feature | Description |
|---|---|
| SOCKS5 protocol | Full TCP support with optional UDP ASSOCIATE via Dante |
| Flexible authentication | Open proxy, single user, or multi-user with file or env |
| IP allowlist | Restrict access to specific source CIDRs |
| Destination filtering | Block outbound access to IPs or subnets |
| IPv6 support | Optional dual-stack internal listener |
| Custom DNS | Override the container resolver to prevent DNS leaks |
| Configurable timeouts | Fine-tune connect, negotiate, and idle session timeouts |
| Tor routing | One env var routes all traffic through the Tor network |
| Quiet log mode | Suppress per-connection logs for high-throughput deployments |
| Graceful reload | Send `SIGHUP` to hot-reload config without container restart |
| Health check | Docker `HEALTHCHECK` reports true proxy availability |
| Performance tuned | Kernel TCP tuning, fd limits, Dante worker pre-forking |

---

## Quick Start

### Option 1 — Docker Hub (recommended)

```bash
docker run -d \
  --name socks5-server \
  --restart unless-stopped \
  -p 54178:1080 \
  lahiru98s/docker-socks5-proxy:latest
```

With authentication:

```bash
docker run -d \
  --name socks5-server \
  --restart unless-stopped \
  -p 54178:1080 \
  -e PROXY_USER=alice \
  -e PROXY_PASS=secret \
  lahiru98s/docker-socks5-proxy:latest
```

With Docker Compose using the prebuilt image:

```bash
curl -O https://raw.githubusercontent.com/nooblk-98/docker-socks5-proxy/main/docker-compose.prebuilt.yml
docker compose -f docker-compose.prebuilt.yml up -d
```

### Option 2 — Build from source

```bash
git clone https://github.com/nooblk-98/docker-socks5-proxy.git
cd docker-socks5-proxy
cp .env.example .env
# Edit .env as needed
docker compose up -d --build
```

The proxy listens on port `54178` by default (configurable via `SOCKS5_PORT`).

---

## Configuration Reference

| Variable | Default | Description |
|---|---|---|
| `SOCKS5_PORT` | `54178` | Host port mapped to the SOCKS5 listener |
| `PROXY_USER` | _(empty)_ | Single username — leave empty for open proxy |
| `PROXY_PASS` | _(empty)_ | Single user password |
| `PROXY_USERS` | _(empty)_ | Comma-separated `user:pass` pairs (overrides single user) |
| `ALLOWED_CIDR` | _(empty)_ | Comma-separated source CIDRs permitted to connect (empty = all) |
| `BLOCKED_DESTINATIONS` | _(empty)_ | Comma-separated destination IPs/CIDRs to block outbound |
| `UDP_ENABLED` | `false` | Enable SOCKS5 UDP ASSOCIATE |
| `IPV6_ENABLED` | `false` | Add an IPv6 internal listener (`:: 1080`) |
| `DNS_SERVER` | _(empty)_ | Override container DNS resolver (e.g. `1.1.1.1`) |
| `TIMEOUT_CONNECT` | `30` | TCP connect timeout in seconds |
| `TIMEOUT_NEGOTIATE` | `30` | SOCKS5 negotiation timeout in seconds |
| `TIMEOUT_IO` | `86400` | Idle session timeout in seconds |
| `TOR_ENABLED` | `false` | Route all outbound traffic through Tor |
| `LOG_LEVEL` | `normal` | Set to `quiet` to suppress connect/disconnect logs |

---

## Authentication

### Open proxy (no auth)

Leave `PROXY_USER` and `PROXY_PASS` unset (default behavior).

### Single user

```env
PROXY_USER=alice
PROXY_PASS=secret
```

### Multiple users via environment variable

```env
PROXY_USERS=alice:secret,bob:hunter2,carol:p@ssw0rd
```

### Multiple users via file

Create a `users.txt` file — one `user:pass` per line, lines starting with `#` are ignored:

```
# Proxy users
alice:secret
bob:hunter2
```

Mount it in `docker-compose.yml`:

```yaml
volumes:
  - ./users.txt:/etc/proxy-users.txt:ro
```

---

## IP Allowlist

Restrict inbound connections to specific source CIDRs. All other clients are blocked.

```env
ALLOWED_CIDR=203.0.113.0/24,198.51.100.5/32
```

---

## Destination Filtering

Block outbound access to specific IPs or subnets — useful for preventing access to internal networks:

```env
BLOCKED_DESTINATIONS=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
```

---

## UDP Support

Enable the SOCKS5 UDP ASSOCIATE command for DNS and UDP-based applications:

```env
UDP_ENABLED=true
```

---

## IPv6

Bind an additional `::` listener to accept connections from IPv6 clients:

```env
IPV6_ENABLED=true
```

> Docker's default network is IPv4-only. To use IPv6, enable `enable_ipv6` in your Docker daemon configuration.

---

## Custom DNS

Point the container at a specific DNS resolver to prevent leaks:

```env
DNS_SERVER=1.1.1.1
```

---

## Configurable Timeouts

```env
TIMEOUT_CONNECT=30      # Seconds to establish an outbound TCP connection
TIMEOUT_NEGOTIATE=30    # Seconds allowed for the SOCKS5 handshake
TIMEOUT_IO=3600         # Idle session timeout (seconds)
```

---

## Tor Routing

Route all proxied traffic through the Tor network with a single variable:

```env
TOR_ENABLED=true
```

Dante forwards all connections to Tor's local SOCKS5 port (`9050`). The Tor daemon starts automatically inside the container.

> The first connection after startup may be slow while Tor builds its circuits.

---

## Log Level

For high-throughput deployments, suppress per-connection log entries to reduce I/O overhead:

```env
LOG_LEVEL=quiet
```

When set to `quiet`, only errors are logged. Default is `normal` (connect/disconnect/error).

---

## Graceful Config Reload

Send `SIGHUP` to reload Dante's configuration without restarting the container or dropping active connections:

```bash
docker kill --signal=HUP socks5-server
```

