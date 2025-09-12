FROM alpine:latest
WORKDIR /app

RUN apk add --no-cache openssl
COPY tls-cert-generator.sh /app/tls-cert-generator.sh

ENTRYPOINT ["sh", "/app/tls-cert-generator.sh"]