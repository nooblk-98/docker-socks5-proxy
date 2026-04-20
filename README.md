# socks5-docker

A lightweight SOCKS5 proxy server running inside Docker, powered by [Dante](https://www.inet.no/dante/) on Alpine Linux.

## Project Structure

```
socks5-docker/
├── config/
│   └── danted.conf       # Dante server configuration
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
- Minimal Alpine-based image (~10MB)

## Quick Start

```bash
cp .env.example .env
docker compose up -d
```

The server listens on port `54178` by default.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PROXY_USER` | _(empty)_ | Username for auth. Leave empty for open proxy. |
| `PROXY_PASS` | _(empty)_ | Password for auth. |
| `SOCKS5_PORT` | `54178` | Host port to expose the proxy on. |

## Authentication

### Open proxy (no auth)

```bash
docker compose up -d
```

### Username/password

Set in `.env`:

```env
PROXY_USER=alice
PROXY_PASS=secret
```

Then:

```bash
docker compose up -d
```

## Testing

```bash
# Without auth
curl --socks5 <your-server-ip>:54178 https://ifconfig.me

# With auth
curl --socks5 alice:secret@<your-server-ip>:54178 https://ifconfig.me
```

## Firewall

```bash
ufw allow 54178/tcp
```

## Manual Build

```bash
docker build -t socks5-server .
docker run -d -p 54178:1080 socks5-server
```
