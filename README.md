# <img src="localdots.png" height="56" />

![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/rnbw/localdots)

## localdots — HTTPS domains for development

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
# *.localhost domains shouldn't need to be added for typical use cases
127.0.0.1  hello.dev

# after localdots container is up and running,
# you will see a .caroot directory in your $HOME.
brew install step \
    && step certificate install ~/.caroot/certs/root_ca.crt

# that's it, try open the sites configured above
open https://whoami.localhost
open https://hello.dev
```

## About domains

### Using special TLDs

When picking a TLD for local development, you can use one of the special domain names suggested in [RFC6761](https://tools.ietf.org/html/rfc6761), such as `test` or `localhost`.

`localhost` has, [by spec](https://tools.ietf.org/html/rfc6761#section-6.3), the following particularities:

```
1.  Users are free to use localhost names as they would any other
    domain names.  Users may assume that IPv4 and IPv6 address
    queries for localhost names will always resolve to the respective
    IP loopback address.

2.  Application software MAY recognize localhost names as special, or
    MAY pass them to name resolution APIs as they would for other
    domain names.

3.  Name resolution APIs and libraries SHOULD recognize localhost
    names as special and SHOULD always return the IP loopback address
    for address queries and negative responses for all other query
    types.  Name resolution APIs SHOULD NOT send queries for
    localhost names to their configured caching DNS server(s).
```

However, if you expect `anything.localhost` to be resolved to 127.0.0.1 automatically, that might not work. For example, you can open it in Chrome and the browser will resolve it fine. But if you ping it or curl it, you'll get an error unless you add the record in your hosts file.

See https://tools.ietf.org/html/draft-west-let-localhost-be-localhost-06.

### Using any TLD

Using any of the domains above, you can be sure you won't run into any conflicts. But other than that, there's no reason why you cannot use any other "registrable" domain. There are [~1600 possible TLDs](https://www.iana.org/domains/root/db) you can choose from, or even invent your own!

While this can be seen as bad practice, I leave it to you. Personally I've seen several companies or dev teams using `xyz`, `wtf`, `lol`, `dev`, `net`, `host`, or even custom ones (i.e. not in the list) such as using the company name or team.

In my opinion, as long as you 1- know what you are doing, 2- don't shadow an existing domain that you or someone in your team uses (e.g. don't use `gmail.com`...) and 3- keep it scoped to your local development environment, then just use whatever works for you.

As with special domains, remember to add the necessary entries in your hosts file. Alternatively in this case, if you own the domain then you can always add the record in your DNS.

## Contributing
Bugfixes, improvements, proposals are gladly welcome!
