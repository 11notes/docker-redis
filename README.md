![banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# REDIS
![size](https://img.shields.io/docker/image-size/11notes/redis/7.4.5?color=0eb305)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![version](https://img.shields.io/docker/v/11notes/redis/7.4.5?color=eb7a09)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![pulls](https://img.shields.io/docker/pulls/11notes/redis?color=2b75d6)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)[<img src="https://img.shields.io/github/issues/11notes/docker-REDIS?color=7842f5">](https://github.com/11notes/docker-REDIS/issues)![5px](https://github.com/11notes/defaults/blob/main/static/img/transparent5x2px.png?raw=true)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

Run redis rootless, distroless and secure.

# INTRODUCTION 📢

For developers, who are building real-time data-driven applications, Redis is the preferred, fastest, and most feature-rich cache, data structure server, and document and vector query engine.

![REDISINSIGHT](https://github.com/11notes/docker-redis/blob/master/img/RedisInsight.png?raw=true)

# SYNOPSIS 📖
**What can I do with this?** This image will run redis [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md) for more security. Besides being more secure and slim than most images, it also offers additional start parameters to either start Redis in command mode, as a replica or as a in-memory database that persists nothing to disk. Simply provide the command needed:

# COMMANDS 📟
* **--cmd** - Will execute all commands against the Redis database specified via ```REDIS_HOST``` environment variable
* **--replica MASTER** - Will start as replica from MASTER (can be IP, FQDN or container DNS)
* **--in-memory** - Will start Redis only in memory
* **[^1]** - ... and more?

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image has no shell since it is [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)
>* ... this image is auto updated to the latest version via CI/CD
>* ... this image has a health check
>* ... this image runs read-only
>* ... this image is automatically scanned for CVEs before and after publishing
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small
>* ... this image can be used to execute commands after redis has started

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | 11notes/redis:7.4.5 | redis:7.4.5 |
| ---: | :---: | :---: |
| **image size on disk** | 5.71MB | 117MB |
| **process UID/GID** | 1000/1000 | 0/0 |
| **distroless?** | ✅ | ❌ |
| **rootless?** | ✅ | ❌ |


# COMPOSE ✂️
```yaml
name: "kv"

x-image-redis: &image
  image: "11notes/redis:7.4.5"
  read_only: true

services:
  redis:
    <<: *image
    environment:
      REDIS_PASSWORD: "${REDIS_PASSWORD}"
      TZ: "Europe/Zurich"
    networks:
      backend:
    volumes:
      - "redis.etc:/redis/etc"
      - "redis.var:/redis/var"
    tmpfs:
      - "/run:uid=1000,gid=1000"
    restart: "always"

  # start a replica
  replica:
    <<: *image
    environment:
      REDIS_PASSWORD: "${REDIS_PASSWORD}"
      TZ: "Europe/Zurich"
    command: "--replica redis"
    networks:
      backend:
    volumes:
      - "replica.etc:/redis/etc"
      - "replica.var:/redis/var"
    tmpfs:
      - "/run:uid=1000,gid=1000"
    restart: "always"

  # start Redis only in-memory
  in-memory:
    <<: *image
    environment:
      REDIS_PASSWORD: "${REDIS_PASSWORD}"
      TZ: "Europe/Zurich"
    command: "--in-memory"
    networks:
      backend:
    volumes:
      - "in-memory.etc:/redis/etc"
    tmpfs:
      - "/run:uid=1000,gid=1000"
    restart: "always"

  # execute CLI commands via redis-cli
  cli:
    <<: *image
    depends_on:
      redis:
        condition: "service_healthy"
        restart: true
    environment:
      REDIS_HOST: "redis"
      REDIS_PASSWORD: "${REDIS_PASSWORD}"
      TZ: "Europe/Zurich"
    # start redis in cmd mode
    entrypoint: ["/usr/local/bin/redis", "--cmd"]
    # commands to execute in order
    command: 
      - PING
      - --version
      - SET key value NX
      - GET key
    networks:
      backend:

  # demo container to actually view the databases
  gui:
    image: "redis/redisinsight"
    environment:
      RI_REDIS_HOST0: "redis"
      RI_REDIS_PASSWORD0: "${REDIS_PASSWORD}"
      RI_REDIS_HOST1: "replica"
      RI_REDIS_PASSWORD1: "${REDIS_PASSWORD}"
      RI_REDIS_HOST2: "in-memory"
      RI_REDIS_PASSWORD2: "${REDIS_PASSWORD}"
      TZ: "Europe/Zurich"
    ports:
      - "3000:5540/tcp"
    networks:
      backend:
      frontend:

volumes:
  redis.etc:
  redis.var:
  replica.etc:
  replica.var:
  in-memory.etc:

networks:
  frontend:
  backend:
    internal: true
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
| `DEBUG` | Will activate debug option for container image and app (if available) | |
| `REDISCLI_HISTFILE` | Disable history of redis-cli (for security) | /dev/null |
| `REDIS_IP` | IP of Redis server | 0.0.0.0 |
| `REDIS_PORT` | Port of Redis server | 6379 |
| `REDIS_HOST` | IP of upstream Redis server when using ```--cmd``` | |
| `REDIS_PASSWORD` | Password used for authentication | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [7.4.5](https://hub.docker.com/r/11notes/redis/tags?name=7.4.5)

### There is no latest tag, what am I supposed to do about updates?
It is of my opinion that the ```:latest``` tag is dangerous. Many times, I’ve introduced **breaking** changes to my images. This would have messed up everything for some people. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:7.4.5``` you can use ```:7``` or ```:7.4```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/redis:7.4.5
docker pull ghcr.io/11notes/redis:7.4.5
docker pull quay.io/11notes/redis:7.4.5
```

# SOURCE 💾
* [11notes/redis](https://github.com/11notes/docker-REDIS)

# PARENT IMAGE 🏛️
> [!IMPORTANT]
>This image is not based on another image but uses [scratch](https://hub.docker.com/_/scratch) as the starting layer.
>The image consists of the following distroless layers that were added:
>* [11notes/distroless](https://github.com/11notes/docker-distroless/blob/master/arch.dockerfile) - contains users, timezones and Root CA certificates

# BUILT WITH 🧰
* [redis/redis](https://github.com/redis/redis)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

[^1]: Sentinel mode will follow soon as well as the possibility to change the announce IP and port

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-redis/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-redis/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-redis/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 17.07.2025, 16:12:30 (CET)*