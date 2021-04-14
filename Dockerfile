FROM steamcmd/steamcmd:latest

RUN set -x \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y \
        cron \
        libfreetype6 \
        libfreetype6:i386 \
        nano \
        python3 \
        tmux \
        vim \
        winbind \
        wine-stable \
    && mkdir -p /config /config/gamefiles /config/saves \
    && rm -rf /var/lib/apt/lists/* 

COPY Game.ini /root/Game.ini
COPY Engine.ini /root/Engine.ini

COPY init.sh "/init.sh"
RUN chmod +x "/init.sh"

VOLUME /config
WORKDIR /config

ENV STEAMAPPID=526870 \
    STEAMBETA=false

EXPOSE 7777/udp

ENTRYPOINT ["bash", "-c", "/init.sh"]