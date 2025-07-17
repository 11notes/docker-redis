${{ content_synopsis }} This image will run redis [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md) for more security. Besides being more secure and slim than most images, it also offers additional start parameters to either start Redis in command mode, as a replica or as a in-memory database that persists nothing to disk. Simply provide the command needed:

# COMMANDS 📟
* **--cmd** - Will execute all commands against the Redis database specified via ```REDIS_HOST``` environment variable
* **--replica MASTER** - Will start as replica from MASTER (can be IP, FQDN or container DNS)
* **--in-memory** - Will start Redis only in memory

${{ content_uvp }} Good question! Because ...

${{ github:> [!IMPORTANT] }}
${{ github:> }}* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
${{ github:> }}* ... this image has no shell since it is [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)
${{ github:> }}* ... this image is auto updated to the latest version via CI/CD
${{ github:> }}* ... this image has a health check
${{ github:> }}* ... this image runs read-only
${{ github:> }}* ... this image is automatically scanned for CVEs before and after publishing
${{ github:> }}* ... this image is created via a secure and pinned CI/CD process
${{ github:> }}* ... this image is very small
${{ github:> }}* ... this image can be used to execute commands after redis has started

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

${{ content_comparison }}

${{ content_compose }}

${{ content_defaults }}

${{ content_environment }}
| `REDISCLI_HISTFILE` | Disable history of redis-cli (for security) | /dev/null |
| `REDIS_IP` | IP of Redis server | 0.0.0.0 |
| `REDIS_PORT` | Port of Redis server | 6379 |
| `REDIS_HOST` | IP of upstream Redis server when using ```--cmd``` | |
| `REDIS_PASSWORD` | Password used for authentication | |

${{ content_source }}

${{ content_parent }}

${{ content_built }}

${{ content_tips }}

${{ title_caution }}
${{ github:> [!CAUTION] }}
${{ github:> }}* The example compose has a default user account, please provide your own user account and do not blindly copy and paste