# Alpine :: Redis
![size](https://img.shields.io/docker/image-size/11notes/redis/7.0.14?color=0eb305) ![version](https://img.shields.io/docker/v/11notes/redis?color=eb7a09) ![pulls](https://img.shields.io/docker/pulls/11notes/redis?color=2b75d6) ![activity](https://img.shields.io/github/commit-activity/m/11notes/docker-redis?color=c91cb8) ![commit-last](https://img.shields.io/github/last-commit/11notes/docker-redis?color=c91cb8)

Run Redis based on Alpine Linux. Small, lightweight, secure and fast 🏔️

## Volumes
* **/redis/etc** - Directory of redis.conf
* **/redis/var** - Directory of database (if persistence is used)

## Run
```shell
docker run --name redis \
  -v ../etc:/redis/etc \
  -v ../var:/redis/var \
  -d 11notes/redis:[tag]
```

## Defaults
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user docker |
| `uid` | 1000 | user id 1000 |
| `gid` | 1000 | group id 1000 |
| `home` | /redis | home directory of user docker |
| `config` | /redis/etc/redis.conf | redis configuration file |
| `ssl` | /redis/ssl/* | redis SSL configuration, on by default |

## Environment
| Parameter | Value | Default |
| --- | --- | --- |
| `REDIS_PASSWORD` | your redis password | will be created at container start if not set |

## Parent image
* [redis/7-alpine](https://github.com/docker-library/redis/blob/7ef4e925387c9c4063b25e83928a85ff44dddf4d/7.0/alpine/Dockerfile)

## Built with and thanks to
* [Redis](https://redis.io)
* [Alpine Linux](https://alpinelinux.org)

## Tips
* Only use rootless container runtime (podman, rootless docker)
* Don't bind to ports < 1024 (requires root), use NAT/reverse proxy (haproxy, traefik, nginx)