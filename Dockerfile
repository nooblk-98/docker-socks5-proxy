FROM alpine:3.19

RUN apk add --no-cache \
    dante-server \
    shadow \
    iproute2 \
    tor \
    stunnel \
    openssl

COPY config/danted.conf /etc/danted.conf
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1080 1443

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD nc -w 1 127.0.0.1 1080 </dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
