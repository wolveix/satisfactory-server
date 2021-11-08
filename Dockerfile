FROM cm2network/steamcmd:root

RUN set -x \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y sudo=1.8.27-1+deb10u3 --no-install-recommends\
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /config \
    && chown steam:steam /config

COPY init.sh /

COPY --chown=steam:steam Game.ini Engine.ini Scalability.ini run.sh /home/steam/

WORKDIR /config

ENV DEBUG="false" \
    GAMECONFIGDIR="/config/gamefiles/FactoryGame/Saved" \
    GAMESAVESDIR="/home/steam/.config/Epic/FactoryGame/Saved/SaveGames" \
    MAXPLAYERS="16" \
    PGID="1000" \
    PUID="1000" \
    SERVERBEACONPORT="15000" \
    SERVERGAMEPORT="7777" \
    SERVERIP="0.0.0.0" \
    SERVERQUERYPORT="15777" \
    SKIPUPDATE="false" \
    STEAMAPPID="1690800" \
    STEAMBETA="false"

EXPOSE 7777/udp 15000/udp 15777/udp

ENTRYPOINT [ "/init.sh" ]