# Satisfactory Server

This is a Dockerized version of the [Satisfactory](https://store.steampowered.com/app/526870/Satisfactory/) dedicated server.

## Setup

According to [the official wiki](https://satisfactory.fandom.com/wiki/Dedicated_servers), expect to need 5GB - 10GB of RAM. This implementation raises the player cap from 4 to 16.

You'll need to bind a local directory to the Docker container's `/config` directory. This directory will hold the following directories:
- `/gamefiles` - this is for the game's files. They're stored outside of the container to avoid needing to redownload 15GB+ every time you want to rebuild the container.
- `/saves` - this is for the game's saves. They're copied into the container on start

Run the Satisfactory server image like this:

```
docker run -d --name=satisfactory-server -h satisfactory-server -v /path/to/config:/config -p 7777:7777/udp -p 15000:15000/udp -p 15777:15777/udp wolveix/satisfactory-server:latest
```

If you're using [Docker Compose](https://docs.docker.com/compose/):

```
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
        restart: unless-stopped
```

## Experimental Branch

If you want to run a server for the Experimental version of the game, simply add a `STEAMBETA=true` environment variable.

## How to Improve the Multiplayer Experience

The [Satisfactory Wiki](https://satisfactory.fandom.com/wiki/Multiplayer#Engine.ini) recommends a few config tweaks to really get the best out of multiplayer. These changes are already applied to the server, but they need to be applied to your local config too:
- Press `WIN + R`
- Enter `%localappdata%/FactoryGame/Saved/Config/WindowsNoEditor`
- Copy the config data from the wiki into the respective files
- Right-click each of the 3 config files (Engine.ini, Game.ini, Scalability.ini)
- Go to Properties > tick Read-only under the attributes

## Known Issues

- The server log will show various errors; most of which can be safely ignored. As long as the container continues to run and your log looks similar to the example log, the server should be functioning just fine: [example log](https://github.com/wolveix/satisfactory-server/blob/main/server.log)