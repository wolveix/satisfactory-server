# Satisfactory Server

![Release](https://img.shields.io/github/v/release/wolveix/satisfactory-server)
![Docker Pulls](https://img.shields.io/docker/pulls/wolveix/satisfactory-server)
![Docker Stars](https://img.shields.io/docker/stars/wolveix/satisfactory-server)
![Image Size](https://img.shields.io/docker/image-size/wolveix/satisfactory-server)

This is a Dockerized version of the [Satisfactory](https://store.steampowered.com/app/526870/Satisfactory/) dedicated server.

If the server feels too buggy for you, you can try the [saveshare](saveshare/README.md) instead (which relies on client-hosting).

## Setup

Recent updates consume 4GB - 6GB RAM, but [the official wiki](https://satisfactory.wiki.gg/wiki/Dedicated_servers#Requirements) recommends allocating 12GB - 16GB RAM.

You'll need to bind a local directory to the Docker container's `/config` directory. This directory will hold the following directories:

-   `/backups` - the server will automatically backup your saves when the container first starts
-   `/gamefiles` - this is for the game's files. They're stored outside of the container to avoid needing to redownload 8GB+ every time you want to rebuild the container
-   `/overrides` - this is for custom `.ini` configuration file overrides
-   `/saved` - this contains the game's blueprints, saves, and server configuration

Before running the server image, you should find your user ID that will be running the container. This isn't necessary in most cases, but it's good to find out regardless. If you're seeing `permission denied` errors, then this is probably why. Find your ID in `Linux` by running the `id` command. Then grab the user ID (usually something like `1000`) and pass it into the `-e PGID=1000` and `-e PUID=1000` environment variables.

Run the Satisfactory server image like this (this is one command, make sure to copy all of it):<br>

```bash
docker run \
--detach \
--name=satisfactory-server \
--hostname satisfactory-server \
--restart unless-stopped \
--volume /path/to/config:/config \
--env MAXPLAYERS=4 \
--env PGID=1000 \
--env PUID=1000 \
--env ROOTLESS=false \
--env STEAMBETA=false \
--memory-reservation=4G \
--memory 6G \
--publish 7777:7777/udp \
--publish 7777:7777/tcp \
wolveix/satisfactory-server:latest
```

<details>
<summary>Explanation of the command</summary>

* `--detach` -> Starts the container detached from your terminal<br>
If you want to see the logs replace it with `--sig-proxy=false`
* `--name` -> Gives the container a unqiue name
* `--hostname` -> Changes the hostname of the container
* `--restart unless-stopped` -> Automatically restarts the container unless the container was manually stopped
* `--volume` -> Binds the Satisfactory config folder to the folder you specified
Allows you to easily access your savegames
* For the environment (`--env`) variables please see [here](https://github.com/wolveix/satisfactory-server#environment-variables)
* `--memory-reservation=4G` -> Reserves 4GB RAM from the host for the container's use
* `--memory 6G` -> Restricts the container to 6GB RAM
* `--publish` -> Specifies the ports that the container exposes<br>
</details>

### Docker Compose

If you're using [Docker Compose](https://docs.docker.com/compose/):

```yaml
services:
    satisfactory-server:
        container_name: 'satisfactory-server'
        hostname: 'satisfactory-server'
        image: 'wolveix/satisfactory-server:latest'
        ports:
            - '7777:7777/udp'
            - '7777:7777/tcp'
        volumes:
            - '/path/to/config:/config'
        environment:
            MAXPLAYERS: 4
            PGID: 1000
            PUID: 1000
            ROOTLESS: false
            STEAMBETA: false
        restart: unless-stopped
        deploy:
          resources:
            limits:
              memory: 6G
            reservations:
              memory: 4G
```

### Kubernetes

If you are running a [Kubernetes](https://kubernetes.io) cluster, we do have a [service.yaml](https://github.com/wolveix/satisfactory-server/tree/main/cluster/service.yaml) and [statefulset.yaml](https://github.com/wolveix/satisfactory-server/tree/main/cluster/statefulset.yaml) available under the [cluster](https://github.com/wolveix/satisfactory-server/tree/main/cluster) directory of this repo, along with an example [values.yaml](https://github.com/wolveix/satisfactory-server/tree/main/cluster/values.yaml) file.

If you are using [Helm](https://helm.sh), you can find charts for this repo on
[ArtifactHUB](https://artifacthub.io/packages/search?ts_query_web=satisfactory&sort=relevance&page=1). The
[k8s-at-home](https://github.com/k8s-at-home/charts) helm chart for Satisfactory can be installed with the below (please see `cluster/values.yaml` for more information).

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
| `ROOTLESS`              |  `false`  | run the container as a non-root user                |
| `SERVERGAMEPORT`        |  `7777`   | set the game's port                                 |
| `SERVERIP`              | `0.0.0.0` | set the game's ip (usually not needed)              |
| `SERVERSTREAMING`       |  `true`   | toggle whether the game utilizes asset streaming    |
| `SKIPUPDATE`            |  `false`  | avoid updating the game on container start/restart  |
| `STEAMBETA`             |  `false`  | set experimental game version                       |
| `TIMEOUT`               |   `30`    | set client timeout (in seconds)                     |

## Experimental Branch

If you want to run a server for the Experimental version of the game, set the `STEAMBETA` environment variable to `true`.

## Configuration Overrides

While we've made most of the common configuration options through the `.ini` files configurable through environment variables, you may have a niche requirement that we hadn't considered or may not be used by most people. In which case, please place your version of the `.ini` file into the `/config/overrides` directory and the container will use this instead.

**Do note that doing this disables the environment variables specific to the file in question.**

## Modding

Mod support is still a little rough around the edges, but they do now work. This Docker container functions the same as a standalone installation, so you can follow the excellent technical documentation from the community [here](https://docs.ficsit.app/satisfactory-modding/latest/ForUsers/DedicatedServerSetup.html).

The container does **NOT** have an S/FTP server installed directly, as Docker images are intended to carry a single function/process. You can either SFTP into your host that houses the Satisfactory server (trivial to do if you're running Linux), or alternatively you can spin up an S/FTP server through the use of another Docker container using the Docker Compose example listed below:

```yaml
services:
    # only needed for mods
    sftp-server:
        container_name: 'sftp-server'
        image: 'atmoz/sftp:latest'
        volumes:
            - '/path/to/config:/home/your-ftp-user'
        ports:
            - '2222:22'
        # set the user and password, and the user's UID (this should match the PUID and PGID of the satisfactory-server container)
        command: 'your-ftp-user:your-ftp-password:1000'
```

With this, you'll be able to SFTP into your server and access your game files via `/home/your-ftp-user/gamefiles`.

## IPv6 Support

If you want to use IPv6, set the `SERVERIP` variable to empty or to your IPv6 address. By default, we set this to `0.0.0.0` which means that the server will bind to IPv4.

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
