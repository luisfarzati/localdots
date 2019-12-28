# localdots — HTTPS domains for development

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/rnbw/localdots)

### Important

As the title says, this tool is to be used for development. It is not meant to run at production and it hasn't been tested in CI environments either.

Please help report any issues!

## Features

localdots combines [Caddy](https://github.com/caddyserver/caddy) and [smallstep/certificates](https://github.com/smallstep/certificates) with automated configuration and hot reload.

- Generates SSL/TLS certificates automatically
- Reloads Caddy automatically with every change

## Usage

```yaml
# docker-compose.yaml

version: "3"

services:
  proxy:
    image: rnbw/localdots
    ports:
      - 80:80 # for http->https redirection
      - 443:443
    volumes:
      # contains all vhost files
      - ./caddy.d:/caddy.d:ro
      # contains CA config and certs
      - ~/.caroot:/caroot
    # only needed for *.localhost domains
    extra_hosts:
      - "whoami.localhost:127.0.0.1"    

  # example containers
  whoami:
    image: jwilder/whoami
  hello:
    image: nginxdemos/hello
```

```bash
# ./caddy.d/whoami.localhost
whoami.localhost {
  proxy / whoami:8000
}

# ./caddy.d/hello.dev
hello.dev {
  proxy / hello
}
```

```bash
# run all the things
docker-compose up -d

# add the domains to your /etc/hosts file
# *.localhost domains shouldn't need to be added
127.0.0.1  hello.dev

# after localdots container is up and running,
# you will see a .caroot directory in your $HOME.
brew install step \
    && step certificate install ~/.caroot/certs/root_ca.crt

# that's it, try open the sites configured above
open https://whoami.localhost
open https://hello.dev
```
