FROM alpine:3
LABEL maintainer="Luis Farzati (lfarzati@gmail.com)"

ARG PLUGINS=
ARG CADDYFILE=/etc/Caddyfile
ARG CADDY_D=/caddy.d
ARG STEP_CLI_VERSION=0.13.3
ARG STEP_CA_VERSION=0.13.3
ARG STEP_BINPATH=/usr/local/bin
ARG STEPPATH=/caroot

ENV CADDYFILE=${CADDYFILE}
ENV CADDY_D=${CADDY_D}
ENV STEPPATH=${STEPPATH}
ENV LEGO_CA_CERTIFICATES=${STEPPATH}/certs/root_ca.crt
ENV CADDY_PIDFILE=/tmp/caddy.pid

EXPOSE 443

RUN apk add --no-cache \
  ca-certificates libcap curl inotify-tools grep jq \
  && rm -rf /var/cache/apk/* \
  && curl -fsSL -o - \
  "https://caddyserver.com/download/linux/amd64?plugins=${PLUGINS}&license=personal&telemetry=off" \
  | tar --no-same-owner -C /usr/bin/ -xz caddy \
  && curl -fsSL -o - \
  "https://github.com/smallstep/cli/releases/download/v${STEP_CLI_VERSION}/step_${STEP_CLI_VERSION}_linux_amd64.tar.gz" \
  | tar -xz --strip-components 2 -C ${STEP_BINPATH}  \
  && curl -fsSL -o - \
  "https://github.com/smallstep/certificates/releases/download/v${STEP_CA_VERSION}/step-certificates_${STEP_CA_VERSION}_linux_amd64.tar.gz" \
  | tar -zx --strip-components 2 -C ${STEP_BINPATH} \
  && chmod 0755 /usr/bin/caddy \
  && addgroup -S caddy  \
  && adduser -D -S -s /sbin/nologin -G caddy caddy  \
  && setcap cap_net_bind_service=+ep `readlink -f /usr/bin/caddy`  \
  && /usr/bin/caddy -version  \
  && mkdir -p ${CADDY_D} ${STEPPATH}  \
  && chown -R caddy ${STEPPATH}

COPY Caddyfile /etc/
COPY start.sh /

RUN chmod +x /start.sh

USER caddy

ENTRYPOINT ["/start.sh"]
