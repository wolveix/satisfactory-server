# Satisfactory Server

![Release](https://img.shields.io/github/v/release/wolveix/satisfactory-server)
![Docker Pulls](https://img.shields.io/docker/pulls/wolveix/satisfactory-server)
![Docker Stars](https://img.shields.io/docker/stars/wolveix/satisfactory-server)
![Image Size](https://img.shields.io/docker/image-size/wolveix/satisfactory-server)

This is a Dockerized version of the [Satisfactory](https://store.steampowered.com/app/526870/Satisfactory/) dedicated server.

## Notice

If you're currently playing `v4` (early access, **not** experimental), then please see the [v4 branch](https://github.com/wolveix/satisfactory-server/tree/v4).

## Setup

According to [the official wiki](https://satisfactory.fandom.com/wiki/Dedicated_servers), expect to need 5GB - 10GB of RAM. This implementation raises the player cap from 4 to 8 by default, but you can specify any number by using the `MAXPLAYERS` environment variable.

You'll need to bind a local directory to the Docker container's `/config` directory. This directory will hold the following directories:

- `/backups` - the server will automatically backup your saves when the container first starts
- `/gamefiles` - this is for the game's files. They're stored outside of the container to avoid needing to redownload 15GB+ every time you want to rebuild the container
- `/saves` - this is for the game's saves. They're copied into the container on start

Before running the server image, you should find your user ID that will be running the container. This isn't necessary in most cases, but it's good to find out regardless. If you're seeing `permission denied` errors, then this is probably why. Find your ID in `Linux` by running the `id` command. Then grab the user ID (usually something like `1000`) and pass it into the `-e PGID=1000` and `-e PUID=1000` environment variables.

Run the Satisfactory server image like this:

```bash
docker run -d --name=satisfactory-server -h satisfactory-server -e MAXPLAYERS=8 -e PGID=1000 -e PUID=1000 -e STEAMBETA=false -v /path/to/config:/config -p 7777:7777/udp -p 15000:15000/udp -p 15777:15777/udp wolveix/satisfactory-server:latest
```

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
            - MAXPLAYERS=8
            - PGID=1000
            - PUID=1000
            - STEAMBETA=false
        restart: unless-stopped
```

## Environment Variables

| Parameter | Function |
| :----: | --- |
| `DEBUG` | for debugging the server |
| `MAXPLAYERS` | set the player limit for your server |
| `PGID` | set the group ID of the user the server will run as |
| `PUID` | set the user ID of the user the server will run as |
| `SERVERBEACONPORT` | set the game's beacon port |
| `SERVERGAMEPORT` | set the game's port |
| `SERVERIP` | set the game's ip (usually not needed) |
| `SERVERQUERYPORT` | set the game's query port |
| `SKIPUPDATE` | avoid updating the game on container start/restart |

## Loading Your Save

If you want to upload your own save to the server, you'll need to do the following workaround as there's no UI for this in-game just yet.

Per the instructions [here](https://satisfactory.fandom.com/wiki/Dedicated_servers#Loading_save_file), you'll want to place your savefile in the `/config/saves` directory. Before the next step, you'll need to find out your session name. You can find the session name from either the `Load Menu`, or through a [save editor](https://satisfactory-calculator.com/en/interactive-map)

Once you've done this, connect to the server in-game. From the `Server Settings` tab, insert your session name into the appropriate field. You may need to copy & paste the name in and immediately press `ENTER`, as the UI seems to constantly refresh.

## Experimental Branch

If you want to run a server for the Experimental version of the game, set the `STEAMBETA` environment variable to `true`.

## How to Improve the Multiplayer Experience

The [Satisfactory Wiki](https://satisfactory.fandom.com/wiki/Multiplayer#Engine.ini) recommends a few config tweaks to really get the best out of multiplayer. These changes are already applied to the server, but they need to be applied to your local config too:

- Press `WIN + R`
- Enter `%localappdata%/FactoryGame/Saved/Config/WindowsNoEditor`
- Copy the config data from the wiki into the respective files
- Right-click each of the 3 config files (Engine.ini, Game.ini, Scalability.ini)
- Go to Properties > tick Read-only under the attributes

## Known Issues

- The container is run as `root`. This is pretty common for Docker images, but is bad practice for security reasons. This change was made to address [permissions issues](https://github.com/wolveix/satisfactory-server/issues/44)
- The server log will show various errors; most of which can be safely ignored. As long as the container continues to run and your log looks similar to the example log, the server should be functioning just fine: [example log](https://github.com/wolveix/satisfactory-server/blob/main/server.log)
