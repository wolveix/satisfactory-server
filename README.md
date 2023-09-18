# Satisfactory Server

![Release](https://img.shields.io/github/v/release/wolveix/satisfactory-server)
![Docker Pulls](https://img.shields.io/docker/pulls/wolveix/satisfactory-server)
![Docker Stars](https://img.shields.io/docker/stars/wolveix/satisfactory-server)
![Image Size](https://img.shields.io/docker/image-size/wolveix/satisfactory-server)

This is a Dockerized version of the [Satisfactory](https://store.steampowered.com/app/526870/Satisfactory/) dedicated server.

## Setup

According to [the official wiki](https://satisfactory.wiki.gg/wiki/Dedicated_servers#Requirements), expect to need 12GB - 16GB of RAM.

You'll need to bind a local directory to the Docker container's `/config` directory. This directory will hold the following directories:

-   `/backups` - the server will automatically backup your saves when the container first starts
-   `/gamefiles` - this is for the game's files. They're stored outside of the container to avoid needing to redownload 8GB+ every time you want to rebuild the container
-   `/overrides` - this is for custom `.ini` configuration file overrides
-   `/saved` - this contains the game's blueprints, saves, and server configuration

Before running the server image, you should find your user ID that will be running the container. This isn't necessary in most cases, but it's good to find out regardless. If you're seeing `permission denied` errors, then this is probably why. Find your ID in `Linux` by running the `id` command. Then grab the user ID (usually something like `1000`) and pass it into the `-e PGID=1000` and `-e PUID=1000` environment variables.

Run the Satisfactory server image like this:<br>
Note: This is one command make sure to copy all of it!

```bash
docker run \
--detached \
--name=satisfactory-server \
--hostname satisfactory-server \
--restart unless-stopped \
--volume /path/to/config:/config \
--env MAXPLAYERS=4 \
--env PGID=1000 \
--env PUID=1000 \
--env STEAMBETA=false \
--memory-reservation=12G \
--memory 16G \
--publish 7777:7777/udp \
--publish 15000:15000/udp \
--publish 15777:15777/udp \
wolveix/satisfactory-server:latest
```

<details> 
<summary>Explanation of the command:</summary>

* `--detached` -> Starts the container detached from your terminal.<br> 
If you want to see the logs replace it with `--sig-proxy=false`.
* `--name` -> Gives the container a unqiue name.
* `--hostname` -> Changes the hostname of the container.
* `--restart unless-stopped` -> Enables the restart policy that restarts the container unless it was stopped by the user.
* `--volume` -> Binds the satisfactory config folder to the folder you specified.
Allows you to easily access your savegames.
* For the environment (`--env`) variables please see [here](https://github.com/wolveix/satisfactory-server#environment-variables).
* `--memory-reservation` -> Is a memory soft limit.
* `--memory 16G` -> Limits the RAM that the container uses to 16 Gigabytes.
* `--publish` -> Specifies the ports that the container exposes.<br> 
</details>

### Docker Compose

If you're using [Docker Compose](https://docs.docker.com/compose/):

```yaml
version: '3'
services:
    satisfactory-server:
        container_name: 'satisfactory-server'
        hostname: 'satisfactory-server'
        image: 'wolveix/satisfactory-server:latest'
        ports:
            - '7777:7777/udp'
            - '15000:15000/udp'
            - '15777:15777/udp'
        volumes:
            - '/path/to/config:/config'
        environment:
            - MAXPLAYERS=4
            - PGID=1000
            - PUID=1000
            - STEAMBETA=false
        restart: unless-stopped
        deploy:
          resources:
            limits:
              memory: 16G
            reservations:
              memory: 12G
```

### Kubernetes

If you are running a [Kubernetes](https://kubernetes.io) cluster, we do have a 
[service.yaml](https://github.com/wolveix/satisfactory-server/cluster/service.yaml) and 
[statefulset.yaml](https://github.com/wolveix/satisfactory-server/cluster/statefulset.yaml) available under the 
[cluster](https://github.com/wolveix/satisfactory-server/cluster) directory of this repo.

If you are using [Helm](https://helm.sh), you can find charts for this repo on 
[ArtifactHUB](https://artifacthub.io/packages/search?ts_query_web=satisfactory&sort=relevance&page=1). The 
[k8s-at-home](https://github.com/k8s-at-home/charts) helm chart for Satisfactory can be installed with the below.

Some suggested default `values.yaml` for the k8s-at-home chart - check out the vaules.yaml for full defaults, and the common chart for more values options.

**values.yaml**

```yaml
env:
    # Environmental variables as below can be passed in this yaml block
    AUTOPAUSE: "true"
    MAXPLAYERS: 3

service:
    main: # Example setup for a LoadBalancer with an external IP
          # MetalLB for example could be used if a Loadbalancer is not provided by your provider
        type: LoadBalancer # Setting an external IP for simple port forwarding
        externalTrafficPolicy: Cluster
        loadBalancerIP: "192.168.2.200" # IP of the satisfactory server

persistence:
    config: # Config/save data stored here
        enabled: true

    server-cache: # Game files stored here
        # This is seperated to allow for backing up only game/config data
        enabled: true
```

The `values.yaml` could then be installed to your Kubernetes cluster with the below

```bash
helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm repo update
helm install satisfactory k8s-at-home/satisfactory -f values.yaml
```

## Environment Variables

| Parameter               |  Default  | Function                                            |
|-------------------------|:---------:|-----------------------------------------------------|
| `AUTOPAUSE`             |  `true`   | pause game when no player is connected              |
| `AUTOSAVEINTERVAL`      |   `300`   | autosave interval in seconds                        |
| `AUTOSAVENUM`           |    `5`    | number of rotating autosave files                   |
| `AUTOSAVEONDISCONNECT`  |  `true`   | autosave when last player disconnects               |
| `CRASHREPORT`           |  `true`   | automatic crash reporting                           |
| `DEBUG`                 |  `false`  | for debugging the server                            |
| `DISABLESEASONALEVENTS` |  `false`  | disable the FICSMAS event (you miserable bastard)   |
| `MAXOBJECTS`            | `2162688` | set the object limit for your server                |
| `MAXPLAYERS`            |    `4`    | set the player limit for your server                |
| `MAXTICKRATE`           |   `30`    | set the maximum sim tick rate for your server       |
| `NETWORKQUALITY`        |    `3`    | set the network quality/bandwidth for your server   |
| `PGID`                  |  `1000`   | set the group ID of the user the server will run as |
| `PUID`                  |  `1000`   | set the user ID of the user the server will run as  |
| `SERVERBEACONPORT`      |  `15000`  | set the game's beacon port                          |
| `SERVERGAMEPORT`        |  `7777`   | set the game's port                                 |
| `SERVERIP`              |    ` `    | set the game's ip (usually not needed)              |
| `SERVERQUERYPORT`       |  `15777`  | set the game's query port                           |
| `SKIPUPDATE`            |  `false`  | avoid updating the game on container start/restart  |
| `STEAMBETA`             |  `false`  | set experimental game version                       |
| `TIMEOUT`               |   `30`    | set client timeout (in seconds)                     |

## Configuration Overrides

While we've made most of the common configuration options through the `.ini` files configurable through environment variables, you may have a niche requirement that we hadn't considered or may not be used by most people. In which case, please your own version of the `.ini` file into `/config/overrides` and the container will use your version instead.

**Do note that doing this disables the environment variables specific to the file in question.**

## Experimental Branch

If you want to run a server for the Experimental version of the game, set the `STEAMBETA` environment variable to `true`.

## How to Improve the Multiplayer Experience

The [Satisfactory Wiki](https://satisfactory.wiki.gg/wiki/Multiplayer#Engine.ini) recommends a few config tweaks to really get the best out of multiplayer. These changes are already applied to the server, but they need to be applied to your local config too:

-   Press `WIN + R`
-   Enter `%localappdata%/FactoryGame/Saved/Config/WindowsNoEditor`
-   Copy the config data from the wiki into the respective files
-   Right-click each of the 3 config files (Engine.ini, Game.ini, Scalability.ini)
-   Go to Properties > tick Read-only under the attributes

## Known Issues

-   The container is run as `root`. This is pretty common for Docker images, but is bad practice for security reasons. This change was made to address [permissions issues](https://github.com/wolveix/satisfactory-server/issues/44)
-   The server log will show various errors; most of which can be safely ignored. As long as the container continues to run and your log looks similar to the example log, the server should be functioning just fine: [example log](https://github.com/wolveix/satisfactory-server/blob/main/server.log)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=wolveix/satisfactory-server&type=Date)](https://star-history.com/#wolveix/satisfactory-server&Date)
