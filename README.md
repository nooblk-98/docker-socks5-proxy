# socks5-docker

A lightweight SOCKS5 proxy server running inside Docker, powered by [Dante](https://www.inet.no/dante/) on Alpine Linux.

## Project Structure

```
socks5-docker/
├── config/
│   └── danted.conf       # Dante SOCKS5 server configuration
├── scripts/
│   └── entrypoint.sh     # Container startup script
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── README.md
```

## Features

- SOCKS5 protocol (TCP)
- Optional username/password authentication
- Auto-detects the container's outbound network interface
- Minimal Alpine-based image

## Quick Start

### 1. Configure environment

```bash
cp .env.example .env
# edit .env if needed
```

### 2. Start the proxy

```bash
docker compose up -d
```

The server listens on port `54178` by default (host network mode — no port mapping needed).

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PROXY_USER` | _(empty)_ | Username for SOCKS5 auth. Leave empty for open proxy. |
| `PROXY_PASS` | _(empty)_ | Password for SOCKS5 auth. |
| `SOCKS5_PORT` | `54178` | Host port to expose the proxy on. |

## Authentication Modes

### Open proxy (no auth)

```bash
docker compose up -d
```

### Username/password auth

```bash
PROXY_USER=alice PROXY_PASS=secret docker compose up -d
```

Or set in `.env`:

```env
PROXY_USER=alice
PROXY_PASS=secret
```

## Test the Proxy

```bash
# Without auth
curl --socks5 <your-server-ip>:54178 https://ifconfig.me

# With auth
curl --socks5 alice:secret@<your-server-ip>:54178 https://ifconfig.me
```

## Build & Run Manually

```bash
docker build -t socks5-server .
docker run -d --network host socks5-server
```

## Firewall

Make sure your firewall allows inbound TCP on the configured port:

```bash
ufw allow 54178/tcp
```
