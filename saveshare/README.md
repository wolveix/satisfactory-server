# Satisfactory Save Sharing

**_Note: Prior to 1.0's release, the group I played with had been relying on solely this for many months. 1.0's release 
drastically improved the stability of dedicated servers, removing the need for SaveShare._**

The dedicated server for Satisfactory introduces a few unique bugs to the game, where multiplayer (through joining a
friend) doesn't. This application introduces save sharing with friends. It's designed to function similarly to how the
game Grounded handles saves.

Everybody runs the client in the background; when the host's game saves, those files are uploaded to a remote SFTP
server (deployed through the Docker Compose below), which the other clients pull from in realtime. This way, if the host
leaves, anyone else can pick up from where they left off.

## Setup

Download the last build from [here](https://github.com/wolveix/satisfactory-server/releases/tag/1.8.2). When you 
initially run it, it'll ask for the following information:

- Server address (IP and port, e.g. `localhost:7790`)
- Server password (the SFTP password)
- Session name (this must be EXACTLY as it is formatted within Satisfactory)

### Docker Compose

If you're using [Docker Compose](https://docs.docker.com/compose/):

```yaml
services:
  satisfactory-saveshare:
    container_name: satisfactory-saveshare
    image: atmoz/sftp:latest
    volumes:
      - /opt/saveshare:/home/saveshare/upload
    ports:
      - "7790:22"
    command: saveshare:PASSWORD_HERE:1001
```

_Note: Do not change the username (`saveshare`) or the UID (`1001`). Only change the password._

### Known Issues

You can't delete blueprints, unless you manually stop everyone from running the application and everyone deletes the
blueprint locally (and server-side)
