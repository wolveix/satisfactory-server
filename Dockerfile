FROM steamcmd/steamcmd:latest

RUN set -x \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y cron sudo wine-stable \
    && mkdir -p /config \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash satisfactory

COPY Game.ini Engine.ini Scalability.ini /home/satisfactory/
COPY backup.sh init.sh /

RUN chmod +x "/backup.sh" "/init.sh"

VOLUME /config
WORKDIR /config

ENV GAMECONFIGDIR="/home/satisfactory/.wine/drive_c/users/satisfactory/Local Settings/Application Data/FactoryGame/Saved" \
    STEAMAPPID="526870" \
    STEAMBETA="false"

EXPOSE 7777/udp

ENTRYPOINT ["bash", "-c", "/init.sh"]