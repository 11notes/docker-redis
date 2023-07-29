# Alpine :: Redis
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
| `config` | /redis/etc/redis.conf | redis configuration file |

## Environment
| Parameter | Value | Default |
| --- | --- | --- |
| `REDIS_PASSWORD` | your redis password | will be created at container start if not set |

## Parent
* [redis/7-alpine](https://github.com/docker-library/redis/blob/7ef4e925387c9c4063b25e83928a85ff44dddf4d/7.0/alpine/Dockerfile)

## Built with
* [Redis](https://redis.io)
* [Alpine Linux](https://alpinelinux.org)

## Tips
* Don't bind to ports < 1024 (requires root), use NAT/reverse proxy
* [Permanent Stroage](https://github.com/11notes/alpine-docker-netshare) - Module to store permanent container data via NFS/CIFS and more