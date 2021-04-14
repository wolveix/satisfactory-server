# Unofficial Satisfactory Server

This is an unofficial implementation of a dedicated server for [Satisfactory](https://store.steampowered.com/app/526870/Satisfactory/).

## Setup

This guide assumes the following:
- You have intermediate knowledge of Linux and Docker
- You have Satisfactory on Steam (Epic may be supported in the future)

You'll need to generate a new save (or grab an existing save) for the server to use. You can usually find your save files located in `C:\Users\Your User\AppData\Local\FactoryGame\Saved\SaveGames\common\your-world.sav`. You need to rename the save to `savefile.sav`, otherwise the server won't read it.

You'll need to bind a local directory to the Docker container. This directory will hold three directories:
- `/gamefiles` - this is for the game's files. They're stored outside of the container to avoid needing to redownload 15GB+ every time you want to rebuild the container.
- `/savefilebackups` - the server will automatically backup your saves every 6 hours into this directory.
- `/savefiles` - this is for the game's saves. They're copied into the container on start, and the saves will be copied back to the host every 30 minutes.

You'll also need to provide your Steam username, password, and Steam Guard when you run the container. To get your Steam Guard code, start the login process using the `steamcmd` Docker image, which will send you an email with the code in (you don't need to finish the login process in that image, you can just press `CTRL + C` to cancel it). You can run that image like this:

```
docker run -it steamcmd/steamcmd +login Your-Steam-Username Your-Steam-Password
```

With your credentials in hand, as well as the absolute path to your config directory, run the Satisfactory server image like this:

```
docker run -d --name=satisfactory-server -h satisfactory-server -e STEAMUSER=Your-Steam-Username -e STEAMPWD=Your-Steam-Password -e STEAMCODE=Your-Steam-Code -v /path/to/config:/config -p 7777:7777/udp wolveix/satisfactory-server:latest
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
        ports:
            - '7777:7777/udp'
        volumes:
            - '/path/to/config:/config'
        restart: unless-stopped
```

## Experimental Branch

If you want to run a server for the Experimental version of the game, simply add a `STEAMBETA=true` environment variable.

## How to Connect to the Server

To join the dedicated server:
- Press `WIN + R`
- Enter `%appdata%`
- Go into Local > FactoryGame > Saved > Config > WindowsNoEditor > open Input.ini in notepad
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

## Known Issues

The server is public, meaning that anyone with your server IP or hostname will be able to join your world.

When the first person joins your server, you'll get the error below in your log. This error doesn't affect the server, it's a biproduct of running Satisfactory "headless":

```
Windows: Error: === Critical error: ===
Windows: Error:
Windows: Error: Fatal error: [File:D:/ws/SB-160502110050-fad/UE4/Engine/Source/Runtime/RenderCore/Private/RenderingThread.cpp] [Line: 855]
Windows: Error: Rendering thread exception:
Windows: Error: Fatal error!
Windows: Error:
Windows: Error: Unhandled Exception: EXCEPTION_ACCESS_VIOLATION reading address 0x00000050
Windows: Error:
Windows: Error: [Callstack] 0x0000000001dcc860 FTexture2DDynamicResource::GetTexture2DRHI() []
Windows: Error: [Callstack] 0x0000000003e17065 WriteRawToTexture_RenderThread() []
Windows: Error: [Callstack] 0x0000000003da87fa TGraphTask<TEnqueueUniqueRenderCommandType<`UAsyncTaskDownloadImage::HandleImageRequest'::`18'::FWriteRawDataToTextureName,<lambda_849dcadaf9ed1a7d4bce65d6b94e4c82> > >::ExecuteTask() []
Windows: Error: [Callstack] 0x000000018005a753 FNamedTaskThread::ProcessTasksUntilQuit() []
Windows: Error: [Callstack] 0x0000000002b5a250 RenderingThreadMain() []
Windows: Error: [Callstack] 0x0000000002b5c930 FRenderingThread::Run() []
Windows: Error: [Callstack] 0x000000018025cd2b FRunnableThreadWin::Run() []
Windows: Error: [Callstack] 0x0000000180255741 FRunnableThreadWin::GuardedRun() []
Windows: Error: [Callstack] 0x000000007bc8f113 DbgUserBreakPoint() []
Windows: Error:
Windows: Error:
Windows: Error:
Windows: Error:
Exit: Executing StaticShutdownAfterError
Windows: FPlatformMisc::RequestExit(1)
Core: Engine exit requested (reason: Win RequestExit)
Log file closed, 04/14/21 16:51:27
```

## Credit

This wouldn't have been possible without the following repos:
- [CM2Walki/CSGO](https://github.com/CM2Walki/CSGO)
- [zig-for/satisfactory-docker](https://github.com/zig-for/satisfactory-docker)