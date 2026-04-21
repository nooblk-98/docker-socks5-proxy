# docker-socks5-proxy

A lightweight SOCKS5 proxy server running inside Docker, powered by [Dante](https://www.inet.no/dante/) on Alpine Linux (~15MB image).

## Project Structure

```
docker-socks5-proxy/
├── config/
│   └── danted.conf       # Dante config template (regenerated at startup)
├── scripts/
│   └── entrypoint.sh     # Container startup & configuration script
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── README.md
```

## Features

| Feature | Description |
|---|---|
| SOCKS5 protocol | Full TCP (and optional UDP) SOCKS5 via Dante |
| Authentication | Open proxy, single user, or multiple users |
| Multi-user file | Mount a `users.txt` file to manage many accounts |
| IP allowlist | Restrict which source IPs can connect |
| Destination filtering | Block outbound access to specific IPs/CIDRs |
| IPv6 support | Optionally bind an IPv6 internal listener |
| UDP support | Enable SOCKS5 UDP ASSOCIATE |
| Custom DNS | Override the container's resolver |
| Configurable timeouts | `TIMEOUT_CONNECT`, `TIMEOUT_NEGOTIATE`, `TIMEOUT_IO` |
| Tor routing | Route all traffic through Tor with one env var |
| Graceful reload | Send `SIGHUP` to reload config without restarting |
| Health check | Docker `HEALTHCHECK` reports real proxy availability |

## Quick Start

### Option 1 — Pull from Docker Hub (recommended)

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

Or with Docker Compose using the prebuilt image:

```bash
curl -O https://raw.githubusercontent.com/nooblk-98/docker-socks5-proxy/main/docker-compose.prebuilt.yml
docker compose -f docker-compose.prebuilt.yml up -d
```

### Option 2 — Build from source

```bash
cp .env.example .env
# edit .env as needed
docker compose up -d
```

The server listens on port `54178` by default.

## Configuration Reference

| Variable | Default | Description |
|---|---|---|
| `SOCKS5_PORT` | `54178` | Host port for the SOCKS5 listener |
| `PROXY_USER` | _(empty)_ | Single username (leave empty for open proxy) |
| `PROXY_PASS` | _(empty)_ | Single password |
| `PROXY_USERS` | _(empty)_ | Comma-separated `user:pass` pairs (overrides single user) |
| `ALLOWED_CIDR` | _(empty)_ | Comma-separated source CIDRs allowed to connect (empty = all) |
| `BLOCKED_DESTINATIONS` | _(empty)_ | Comma-separated destination IPs/CIDRs to block |
| `UDP_ENABLED` | `false` | Enable SOCKS5 UDP ASSOCIATE |
| `IPV6_ENABLED` | `false` | Add an IPv6 internal listener (`:: 1080`) |
| `DNS_SERVER` | _(empty)_ | Override container DNS (e.g. `1.1.1.1`) |
| `TIMEOUT_CONNECT` | `30` | TCP connect timeout in seconds |
| `TIMEOUT_NEGOTIATE` | `30` | SOCKS5 negotiation timeout in seconds |
| `TIMEOUT_IO` | `86400` | Idle session timeout in seconds |
| `TOR_ENABLED` | `false` | Route all outbound traffic through Tor |

---

## Authentication

### Open proxy (no auth)

Leave `PROXY_USER` and `PROXY_PASS` empty (default).

### Single user

```env
PROXY_USER=alice
PROXY_PASS=secret
```

### Multiple users via env

```env
PROXY_USERS=alice:secret,bob:hunter2,carol:p@ssw0rd
```

### Multiple users via file

Create `users.txt` (one `user:pass` per line, `#` for comments):

```
# proxy users
alice:secret
bob:hunter2
```

Then mount it in `docker-compose.yml`:

```yaml
volumes:
  - ./users.txt:/etc/proxy-users.txt:ro
```

---

## IP Allowlist

Allow only specific source CIDRs. All other clients are blocked.

```env
ALLOWED_CIDR=203.0.113.0/24,198.51.100.5/32
```

---

## Destination Filtering

Block outbound access to specific IPs or subnets (e.g. prevent access to internal networks):

```env
BLOCKED_DESTINATIONS=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
```

---

## UDP Support

Enable the SOCKS5 UDP ASSOCIATE command (useful for DNS and some applications):

```env
UDP_ENABLED=true
```

---

## IPv6

Add a `::` listener so IPv6 clients can connect:

```env
IPV6_ENABLED=true
```

> Docker's default network is IPv4-only. Enable `enable_ipv6` in Docker daemon settings if needed.

---

## Custom DNS

Prevent DNS leaks by pointing the container at a specific resolver:

```env
DNS_SERVER=1.1.1.1
```

---

## Configurable Timeouts

```env
TIMEOUT_CONNECT=30      # seconds to establish outbound TCP connection
TIMEOUT_NEGOTIATE=30    # seconds allowed for SOCKS5 handshake
TIMEOUT_IO=3600         # idle session timeout (3600 = 1 hour)
```

---

## Tor Routing

Route all proxied traffic through the Tor network:

```env
TOR_ENABLED=true
```

Dante is configured to forward all connections to Tor's local SOCKS5 port (9050). The Tor daemon starts automatically inside the container.

> First connection after startup may be slow while Tor builds circuits.

---

## Graceful Config Reload

Modify environment variables, then send `SIGHUP` to reload Dante without dropping the container:

```bash
docker kill --signal=HUP socks5-server
```

---

## Testing

```bash
# Open proxy
curl --socks5 <host>:54178 https://ifconfig.me

# With authentication
curl --socks5 alice:secret@<host>:54178 https://ifconfig.me

# Check Tor exit IP
TOR_ENABLED=true docker compose up -d
curl --socks5 <host>:54178 https://check.torproject.org/api/ip
```

---

## Firewall

```bash
ufw allow 54178/tcp
```

---

## Manual Build

```bash
docker build -t socks5-server .
docker run -d \
  -p 54178:1080 \
  -e PROXY_USER=alice \
  -e PROXY_PASS=secret \
  socks5-server
```
