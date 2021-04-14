# Unofficial Satisfactory Server

This is an unofficial implementation of a dedicated server for [Satisfactory](https://store.steampowered.com/app/526870/Satisfactory/).

## Setup

This guide assumes the following:
- You have intermediate knowledge of Linux and Docker
- You have Satisfactory on Steam (Epic may be supported in the future)

You'll need to generate a new save (or grab an existing save) for the server to use. You can usually find your save files located in `C:\Users\Your User\AppData\Local\FactoryGame\Saved\SaveGames\common\your-world.sav`. You need to rename the save to `savefile.sav`, otherwise the server won't read it.

You'll need to bind a local directory to the Docker container. This directory will hold two directories:
- `/gamefiles` - this is for the game's files. They're stored outside of the container to avoid needing to redownload 15GB+ every time you want to rebuild the container.
- `/savefiles` - this is for the game's saves. They're copied into the container on start, and the saves will be copied back to the host every 30 minutes.

You'll also need to provide your Steam username, password, and Steam Guard when you run the container. To get your Steam Guard code, start the login process using the `steamcmd` Docker image, which will send you an email with the code in (you don't need to finish the login process in that image, you can just press `CTRL + C` to cancel it). You can run that image like this:

```
docker run -it steamcmd/steamcmd +login Your-Steam-Username Your-Steam-Password
```

With your credentials in hand, as well as the absolute path to your config directory, run the Satisfactory server image like this:

```
docker run -d --name=satisfactory-server -e STEAMUSER=Your-Steam-Username -e STEAMPWD=Your-Steam-Password -e STEAMCODE=Your-Steam-Code -v /path/to/config:/config -p 7777:7777/udp wolveix/satisfactory-server:earlyaccess
```

If you're using [Docker Compose](https://docs.docker.com/compose/):

```
version: '3'
services:
    satisfactory-server:
        container_name: 'satisfactory-server'
        image: 'wolveix/satisfactory-server:earlyaccess'
        environment:
            - STEAMUSER=Your-Steam-Username
            - STEAMPWD=Your-Steam-Password
            - STEAMCODE=Your-Steam-Code
        ports:
            - '7777:7777/udp'
        volumes:
            - '/path/to/config:/config'
        restart: unless-stopped
```

## Credit

This wouldn't have been possible without the following repos:
- [CM2Walki/CSGO](https://github.com/CM2Walki/CSGO)
- [zig-for/satisfactory-docker](https://github.com/zig-for/satisfactory-docker)