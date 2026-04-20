FROM alpine:3.19

RUN apk add --no-cache dante-server shadow iproute2

COPY config/danted.conf /etc/danted.conf
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1080

ENTRYPOINT ["/entrypoint.sh"]
