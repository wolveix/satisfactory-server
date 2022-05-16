# Satisfactory Server

![Release](https://img.shields.io/github/v/release/wolveix/satisfactory-server)
![Docker Pulls](https://img.shields.io/docker/pulls/wolveix/satisfactory-server)
![Docker Stars](https://img.shields.io/docker/stars/wolveix/satisfactory-server)
![Image Size](https://img.shields.io/docker/image-size/wolveix/satisfactory-server)

This is a Dockerized version of the [Satisfactory](https://store.steampowered.com/app/526870/Satisfactory/) dedicated server.

## Setup

According to [the official wiki](https://satisfactory.fandom.com/wiki/Dedicated_servers), expect to need 5GB - 10GB of RAM.

You'll need to bind a local directory to the Docker container's `/config` directory. This directory will hold the following directories:

-   `/backups` - the server will automatically backup your saves when the container first starts
-   `/gamefiles` - this is for the game's files. They're stored outside of the container to avoid needing to redownload 15GB+ every time you want to rebuild the container
-   `/saves` - this is for the game's saves. They're copied into the container on start

Before running the server image, you should find your user ID that will be running the container. This isn't necessary in most cases, but it's good to find out regardless. If you're seeing `permission denied` errors, then this is probably why. Find your ID in `Linux` by running the `id` command. Then grab the user ID (usually something like `1000`) and pass it into the `-e PGID=1000` and `-e PUID=1000` environment variables.

Run the Satisfactory server image like this:

```bash
docker run -d --name=satisfactory-server -h satisfactory-server -e MAXPLAYERS=4 -e PGID=1000 -e PUID=1000 -e STEAMBETA=false -v /path/to/config:/config -p 7777:7777/udp -p 15000:15000/udp -p 15777:15777/udp wolveix/satisfactory-server:latest
```

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
```

### Kubernetes

If you are running a [Kubernetes](https://kubernetes.io) cluster & using [Helm](https://helm.sh), Helm charts can be found on [ArtifactHUB](https://artifacthub.io/packages/search?ts_query_web=satisfactory&sort=relevance&page=1).  For example the [k8s-at-home](https://github.com/k8s-at-home/charts) helm chart for Satisfactory can be installed with the below.

Some suggested default `values.yaml` for the k8s-at-home chart - check out the vaules.yaml for full defaults, and the common chart for more values options.

**values.yaml**

```yaml
env:
    # Environmental variables as below can be passed in this yaml block
    # e.g.
    AUTOPAUSE: "true"
    MAXPLAYERS: 3

service:
    main: # Example setup for a LoadBalancer with a Ip outside cluster
          # MetalLB for example could be used if a Loadbalancer not provided by your provider.
        type: LoadBalancer # Setting Ip external to cluster for easy port forward
        externalTrafficPolicy: Cluster
        loadBalancerIP: "192.168.2.200" # IP of the satisfactory server

persistence:
    config: # Save & config data stored here
        enabled: true

    server-cache: # Downloaded game files stored here.
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
| ----------------------- | :-------: | --------------------------------------------------- |
| `AUTOPAUSE`             |   `true`  | pause game when no player is connected              |
| `AUTOSAVEINTERVAL`      |   `300`   | autosave interval in seconds                        |
| `AUTOSAVENUM`           |    `3`    | number of rotating autosave files                   |
| `AUTOSAVEONDISCONNECT`  |   `true`  | autosave when last player disconnects               |
| `CRASHREPORT`           |   `true`  | automatic crash reporting                           |
| `DEBUG`                 |  `false`  | for debugging the server                            |
| `DISABLESEASONALEVENTS` |  `false`  | disable the FICSMAS event (you miserable bastard)   |
| `MAXPLAYERS`            |    `4`    | set the player limit for your server                |
| `PGID`                  |   `1000`  | set the group ID of the user the server will run as |
| `PUID`                  |   `1000`  | set the user ID of the user the server will run as  |
| `SERVERBEACONPORT`      |  `15000`  | set the game's beacon port                          |
| `SERVERGAMEPORT`        |   `7777`  | set the game's port                                 |
| `SERVERIP`              | `0.0.0.0` | set the game's ip (usually not needed)              |
| `SERVERQUERYPORT`       |  `15777`  | set the game's query port                           |
| `SKIPUPDATE`            |  `false`  | avoid updating the game on container start/restart  |
| `STEAMBETA`             |  `false`  | set experimental game version                       |

## Loading Your Save

If you want to upload your own save to the server, you'll need to do the following workaround as there's no UI for this in-game just yet.

Per the instructions [here](https://satisfactory.fandom.com/wiki/Dedicated_servers#Loading_save_file), you'll want to place your savefile in the `/config/saves` directory. Before the next step, you'll need to find out your session name. You can find the session name from either the `Load Menu`, or through a [save editor](https://satisfactory-calculator.com/en/interactive-map)

Once you've done this, connect to the server in-game. From the `Server Settings` tab, insert your session name into the appropriate field. You may need to copy & paste the name in and immediately press `ENTER`, as the UI seems to constantly refresh.

## Experimental Branch

If you want to run a server for the Experimental version of the game, set the `STEAMBETA` environment variable to `true`.

## How to Improve the Multiplayer Experience

The [Satisfactory Wiki](https://satisfactory.fandom.com/wiki/Multiplayer#Engine.ini) recommends a few config tweaks to really get the best out of multiplayer. These changes are already applied to the server, but they need to be applied to your local config too:

-   Press `WIN + R`
-   Enter `%localappdata%/FactoryGame/Saved/Config/WindowsNoEditor`
-   Copy the config data from the wiki into the respective files
-   Right-click each of the 3 config files (Engine.ini, Game.ini, Scalability.ini)
-   Go to Properties > tick Read-only under the attributes

## Known Issues

-   The container is run as `root`. This is pretty common for Docker images, but is bad practice for security reasons. This change was made to address [permissions issues](https://github.com/wolveix/satisfactory-server/issues/44)
-   The server log will show various errors; most of which can be safely ignored. As long as the container continues to run and your log looks similar to the example log, the server should be functioning just fine: [example log](https://github.com/wolveix/satisfactory-server/blob/main/server.log)
