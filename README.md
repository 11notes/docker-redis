![Banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# 🏔️ Alpine - Redis
![size](https://img.shields.io/docker/image-size/11notes/redis/7.2.4?color=0eb305) ![version](https://img.shields.io/docker/v/11notes/redis/7.2.4?color=eb7a09) ![pulls](https://img.shields.io/docker/pulls/11notes/redis?color=2b75d6) ![activity](https://img.shields.io/github/commit-activity/m/11notes/docker-redis?color=c91cb8) ![commit-last](https://img.shields.io/github/last-commit/11notes/docker-redis?color=c91cb8) ![stars](https://img.shields.io/docker/stars/11notes/redis?color=e6a50e)

**Redis, as fast and secure as it can be**

# SYNOPSIS
What can I do with this? This image will provide you by default with the most secure way to run Redis. You can run the image stand-alone, in a cluster or as a replica. You can run it with persistence (default) or without.

# VOLUMES
* **/redis/etc** - Directory of redis.conf
* **/redis/var** - Directory of AOF and RDB
* **/redis/ssl** - Directory of SSL certificates

# COMPOSE
```yaml
version: "3.8"
services:
  redis:
    image: "11notes/redis:7.2.4"
    container_name: "redis"
    environment:
      REDIS_PASSWORD: "**************"
      TZ: Europe/Zurich
    ports:
      - "6379:6379/tcp"
    volumes:
      - "${PWD}/redis/etc:/redis/etc"
      - "${PWD}/redis/var:/redis/var"
    networks:
      - redis
networks:
  redis:
    driver: bridge
    internal: true
```

# DEFAULT SETTINGS
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user docker |
| `uid` | 1000 | user id 1000 |
| `gid` | 1000 | group id 1000 |
| `home` | /redis | home directory of user docker |
| `config` | /redis/etc/default.conf | config |

# ENVIRONMENT
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Show debug information | |
| `REDIS_PASSWORD` | password for redis | will create a password at start if none is set |
| `REDIS_ENABLE_TLS` | enable TLS | |
| `REDIS_DISABLE_PERSISTANCE` | if set, will disable persistance and use in-memory storage only | |
| `REDIS_MASTER` | start this instance as replica of master (IP or FQDN) | |

# PARENT IMAGE
* [11notes/alpine:stable](https://hub.docker.com/r/11notes/alpine)

# BUILT WITH
* [redis](https://redis.io)
* [alpine](https://alpinelinux.org)

# TIPS
* Only use rootless container runtime (podman, rootless docker)
* Allow non-root ports < 1024 via `echo "net.ipv4.ip_unprivileged_port_start=53" > /etc/sysctl.d/ports.conf`
* Use a reverse proxy like Traefik, Nginx to terminate TLS with a valid certificate
* Use Let’s Encrypt certificates to protect your SSL endpoints

# ElevenNotes<sup>™️</sup>
This image is provided to you at your own risk. Always make backups before updating an image to a new version. Check the changelog for breaking changes.
    