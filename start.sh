#!/bin/sh

reload_caddy() {
  if [ -f $CADDY_PIDFILE ]; then
    kill -SIGUSR1 $(cat $CADDY_PIDFILE)
  else
    PROVISIONER=$(cat $STEPPATH/config/ca.json | jq -r ".authority.provisioners[0].name")
    LEGO_CA_CERTIFICATES=$STEPPATH/certs/root_ca.crt /usr/bin/caddy \
      --conf $CADDYFILE \
      --log stdout \
      -ca https://localhost:8443/acme/acme/directory \
      -email $PROVISIONER \
      -disable-tls-alpn-challenge \
      -pidfile $CADDY_PIDFILE &
  fi
}

# First-time CA configuration
if [ ! -f $STEPPATH/config/ca.json ]; then
  echo "$STEPPATH/config/ca.json not found; creating new CA"

  PROVISIONER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)@localdots.example
  PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1) \
    && echo $PASSWORD > /tmp/password \
    && step ca init \
      --name=localdots \
      --dns=localhost \
      --address=127.0.0.1:8443 \
      --provisioner=$PROVISIONER \
      --password-file=/tmp/password \
    && mv /tmp/password $STEPPATH/secrets/password \
    && step ca provisioner add acme --type ACME
fi

# Starts ACME server and Caddy
step-ca --password-file $STEPPATH/secrets/password $STEPPATH/config/ca.json &
sleep 1
rm -f $CADDY_PIDFILE
reload_caddy

# Caddy configuration watcher
inotifywait -e "create,delete,modify,move" --monitor $CADDY_D --monitor $CADDYFILE | \
  while read -r notifies;
  do
    echo
    echo "$notifies"
    reload_caddy
  done
