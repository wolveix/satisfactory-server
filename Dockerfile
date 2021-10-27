FROM cm2network/steamcmd:latest

COPY Game.ini Engine.ini Scalability.ini /home/steam/
COPY init.sh /home/steam/init.sh

ENV GAMECONFIGDIR="/home/steam/config/gamefiles/FactoryGame/Saved" \
    STEAMAPPID="1690800" \
    STEAMBETA="false"

RUN mkdir /home/steam/config
VOLUME /home/steam/config
WORKDIR /home/steam/config

EXPOSE 7777/udp 15000/udp 15777/udp

ENTRYPOINT [ "/home/steam/init.sh" ]
