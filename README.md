# Unofficial Satisfactory Server

This is an unofficial implementation of a dedicated server for [Satisfactory](https://store.steampowered.com/app/526870/Satisfactory/).

## Setup

This guide assumes the following:
- You have intermediate knowledge of Linux and Docker
- You have Satisfactory on Steam (Epic may be supported in the future)

You'll need to generate a new save (or grab an existing save) for the server to use. You can usually find your save files located in `C:\Users\Your User\AppData\Local\FactoryGame\Saved\SaveGames\common\your-world.sav`. You need to rename the save to `savefile.sav`, otherwise the server won't read it.

You'll need to bind a local directory to the Docker container's `/config` directory. This directory will hold the following directories:
- `/gamefiles` - this is for the game's files. They're stored outside of the container to avoid needing to redownload 15GB+ every time you want to rebuild the container.
- `/savefilebackups` - the server will automatically backup your saves every 6 hours into this directory.
- `/savefiles` - this is for the game's saves. They're copied into the container on start, and the saves will be copied back to the host every 30 minutes.
- `/steam` - this retains your Steam credentials, simplifying the update process.

You'll also need to provide your Steam username, password, and Steam Guard code when you first run the container. To get your Steam Guard code, start the login process using the `steamcmd` Docker image, which will send you an email with the code in (you don't need to finish the login process in that image, you can just press `CTRL + C` to cancel it). You can run that image like this:

```
docker run -it steamcmd/steamcmd +login Your-Steam-Username Your-Steam-Password
```

With your credentials in hand, as well as the absolute path to your config directory, run the Satisfactory server image like this:

```
docker run -d --name=satisfactory-server -h satisfactory-server -e STEAMUSER=Your-Steam-Username -e STEAMPWD=Your-Steam-Password -e STEAMCODE=Your-Steam-Code -e MAXBACKUPS=10 -v /path/to/config:/config -p 7777:7777/udp wolveix/satisfactory-server:latest
```

If you're using [Docker Compose](https://docs.docker.com/compose/):

```
version: '3'
services:
    satisfactory-server:
        container_name: 'satisfactory-server'
        hostname: 'satisfactory-server'
        image: 'wolveix/satisfactory-server:latest'
        environment:
            - STEAMUSER=Your-Steam-Username
            - STEAMPWD=Your-Steam-Password
            - STEAMCODE=Your-Steam-Code
            - MAXBACKUPS=10
        ports:
            - '7777:7777/udp'
        volumes:
            - '/path/to/config:/config'
        restart: unless-stopped
```

You won't need to re-obtain your Steam Guard code after the initial creation.

## Experimental Branch

If you want to run a server for the Experimental version of the game, simply add a `STEAMBETA=true` environment variable.

## How to Connect to the Server

To join the dedicated server:
- Press `WIN + R`
- Enter `%localappdata%/FactoryGame/Saved/Config/WindowsNoEditor`
- Open Input.ini in notepad
- Paste the following at the end of the file:

```
[/script/engine.inputsettings]
ConsoleKey=F6
ConsoleKeys=F6
```

Open Satisfactory, press `F6` on the main menu and you should see a console appear. Run:
```
Open your.server.ip
```

It should start loading into the world almost instantly. If it doesn't, then it's probably going to timeout after 20 seconds. 

## How to Improve the Multiplayer Experience

The [Satisfactory Wiki](https://satisfactory.fandom.com/wiki/Multiplayer#Engine.ini) recommends a few config tweaks to really get the best out of multiplayer. These changes are already applied to the server, but they need to be applied to your local config too:
- Press `WIN + R`
- Enter `%localappdata%/FactoryGame/Saved/Config/WindowsNoEditor`
- Copy the config data from the wiki into the respective files
- Right-click each of the 3 config files (Engine.ini, Game.ini, Scalability.ini)
- Go to Properties > tick Read-only under the attributes

## Known Issues

The server is public, meaning that anyone with your server IP or hostname will be able to join your world.

## Credit

This wouldn't have been possible without the following repos:
- [CM2Walki/CSGO](https://github.com/CM2Walki/CSGO)
- [zig-for/satisfactory-docker](https://github.com/zig-for/satisfactory-docker)
