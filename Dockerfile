FROM alpine:3.21

RUN apk add --no-cache \
    dante-server \
    shadow \
    iproute2 \
    netcat-openbsd \
    tor

COPY config/danted.conf /etc/danted.conf
COPY --chmod=755 scripts/entrypoint.sh /entrypoint.sh

EXPOSE 1080

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
    CMD nc -w 1 127.0.0.1 1080 </dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
