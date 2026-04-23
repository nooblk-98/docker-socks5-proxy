FROM alpine:3.21

LABEL org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.title="docker-socks5-proxy" \
      org.opencontainers.image.description="Lightweight SOCKS5 proxy server powered by Dante on Alpine Linux" \
      org.opencontainers.image.source="https://github.com/nooblk-98/docker-socks5-proxy" \
      org.opencontainers.image.url="https://hub.docker.com/r/lahiru98s/docker-socks5-proxy"

RUN apk add --no-cache \
    dante-server \
    shadow \
    iproute2 \
    netcat-openbsd \
    tor

COPY config/danted.conf /etc/danted.conf
COPY --chmod=755 scripts/entrypoint.sh /entrypoint.sh
COPY --chmod=755 scripts/lib/ /scripts/lib/

EXPOSE 1080

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
    CMD nc -w 1 127.0.0.1 1080 </dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
