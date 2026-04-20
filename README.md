# socks5-docker

A lightweight SOCKS5 proxy server running inside Docker, powered by [Dante](https://www.inet.no/dante/).

## Features

- SOCKS5 protocol (TCP)
- Optional username/password authentication
- Auto-detects the container's outbound network interface
- Single small Alpine-based image

## Quick start

### No authentication (open proxy)

```bash
docker compose up -d
```

The server listens on `localhost:1080`.

### With username/password authentication

```bash
PROXY_USER=alice PROXY_PASS=secret docker compose up -d
```

Or copy `.env.example` to `.env` and fill in the values:

```bash
cp .env.example .env
# edit .env
docker compose up -d
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PROXY_USER` | _(empty)_ | Username for SOCKS5 auth. Leave empty for open proxy. |
| `PROXY_PASS` | _(empty)_ | Password for SOCKS5 auth. |
| `SOCKS5_PORT` | `1080` | Host port to bind the proxy to. |

## Test the proxy

```bash
# Without auth
curl --socks5 localhost:1080 https://ifconfig.me

# With auth
curl --socks5 alice:secret@localhost:1080 https://ifconfig.me
```

## Build manually

```bash
docker build -t socks5-server .
docker run -d -p 1080:1080 socks5-server
```
