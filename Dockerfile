FROM steamcmd/steamcmd:ubuntu-18

RUN set -x \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y gosu --no-install-recommends\
 && rm -rf /var/lib/apt/lists/* \
 && useradd -ms /bin/bash steam \
 && gosu nobody true

RUN mkdir -p /config \
 && chown steam:steam /config

COPY init.sh /
COPY --chown=steam:steam *.ini run.sh /home/steam/

WORKDIR /config

ENV AUTOPAUSE="true" \
    AUTOSAVEINTERVAL="300" \
    AUTOSAVENUM="5" \
    AUTOSAVEONDISCONNECT="true" \
    CRASHREPORT="true" \
    DEBUG="false" \
    DISABLESEASONALEVENTS="false" \
    GAMECONFIGDIR="/config/gamefiles/FactoryGame/Saved" \
    GAMESAVESDIR="/home/steam/.config/Epic/FactoryGame/Saved/SaveGames" \
    MAXOBJECTS="2162688" \
    MAXPLAYERS="4" \
    NETWORKQUALITY="3" \
    PGID="1000" \
    PUID="1000" \
    SERVERBEACONPORT="15000" \
    SERVERGAMEPORT="7777" \
    SERVERIP="0.0.0.0" \
    SERVERQUERYPORT="15777" \
    SKIPUPDATE="false" \
    STEAMAPPID="1690800" \
    STEAMBETA="false" \
    TIMEOUT="300"

EXPOSE 7777/udp 15000/udp 15777/udp

ENTRYPOINT [ "/init.sh" ]
