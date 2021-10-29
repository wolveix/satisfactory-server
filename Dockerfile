FROM cm2network/steamcmd:root

COPY --chown=steam:steam Game.ini Engine.ini Scalability.ini init.sh /home/steam/

RUN mkdir -p /config \
    && chown steam:steam /config

USER steam

WORKDIR /config

ENV GAMECONFIGDIR="/config/gamefiles/FactoryGame/Saved" \
    MAXPLAYERS="16" \
    STEAMAPPID="1690800" \
    STEAMBETA="false"

EXPOSE 7777/udp 15000/udp 15777/udp

ENTRYPOINT [ "/home/steam/init.sh" ]
