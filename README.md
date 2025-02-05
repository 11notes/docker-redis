![Banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# 🏔️ redis on Alpine
[<img src="https://img.shields.io/badge/github-source-blue?logo=github&color=040308">](https://github.com/11notes/docker-redis)![size](https://img.shields.io/docker/image-size/11notes/redis/7.4.2?color=0eb305)![version](https://img.shields.io/docker/v/11notes/redis/7.4.2?color=eb7a09)![pulls](https://img.shields.io/docker/pulls/11notes/redis?color=2b75d6)[<img src="https://img.shields.io/github/issues/11notes/docker-redis?color=7842f5">](https://github.com/11notes/docker-redis/issues)

**Redis with mimalloc and run on Alpine for maximum performance**

# SYNOPSIS 📖
**What can I do with this?** This image will provide you by default with the most secure way to run Redis. You can run the image stand-alone, in a cluster or as a replica. You can run it with persistence (default) or without. With SSL or without. You can even run commands at startup to set some keys. The performance of this image is the highest you will get due to it using mimalloc as memory allocator.

# VOLUMES 📁
* **/redis/etc** - Directory of redis.conf
* **/redis/var** - Directory of AOF and RDB
* **/redis/ssl** - Directory of SSL certificates

# COMPOSE ✂️
```yaml
name: "redis"
services:
  redis:
    image: "11notes/redis:7.4.2"
    container_name: "redis"
    environment:
      REDIS_PASSWORD: ${REDIS_PASSWORD}
      TZ: "Europe/Zurich"
    command:
      - SET mykey1 myvalue1 NX
      - SET mykey2 myvalue2 NX
    ports:
      - "6379:6379/tcp"
    volumes:
      - "redis.etc:/redis/etc"
      - "redis.var:/redis/var"
    restart: always

  sentinel:
    image: "11notes/redis:7.4.2"
    container_name: "sentinel"
    environment:
      REDIS_PASSWORD: ${REDIS_PASSWORD}
      REDIS_MASTER: "redis"
      REDIS_IP: "sentinel"
      TZ: Europe/Zurich
    command: ["sentinel"] # start container as sentinel
    ports:
      - "26379:26379/tcp"
    volumes:
      - "sentinel.etc:/redis/etc"
    restart: always

volumes:
  redis.etc:
  redis.var:
  sentinel.etc:
```

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /redis | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Show debug messages from image **not** app | |
| `REDIS_PASSWORD` | password for redis | will create a password at start if none is set |
| `REDIS_ENABLE_TLS` | enable TLS | |
| `REDIS_DISABLE_PERSISTANCE` | if set, will disable persistance and use in-memory storage only (be aware of this!) | |
| `REDIS_MASTER` | start this instance as replica of master (IP or FQDN) | |
| `REDIS_IP` | IP to bind to or announce (sentinel) | 0.0.0.0 |

# SOURCE 💾
* [11notes/redis](https://github.com/11notes/docker-redis)

# PARENT IMAGE 🏛️
* [11notes/alpine:stable](https://hub.docker.com/r/11notes/alpine)

# BUILT WITH 🧰
* [redis](https://redis.io)
* [alpine](https://alpinelinux.org)

# TIPS 📌
* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS with a valid certificate
* Use Let’s Encrypt certificates to protect your SSL endpoints
  
# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-redis/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-redis/issues), thanks . You can find all my repositories on [github](https://github.com/11notes?tab=repositories).