FROM steamcmd/steamcmd:ubuntu-22

ARG GID=1000
ARG UID=1000

ENV AUTOSAVENUM="5" \
    DEBIAN_FRONTEND="noninteractive" \
    DEBUG="false" \
    DISABLESEASONALEVENTS="false" \
    GAMECONFIGDIR="/config/gamefiles/FactoryGame/Saved" \
    GAMESAVESDIR="/home/steam/.config/Epic/FactoryGame/Saved/SaveGames" \
    LOG="false" \
    MAXOBJECTS="2162688" \
    MAXPLAYERS="4" \
    MAXTICKRATE="30" \
    MULTIHOME="::" \
    PGID="1000" \
    PUID="1000" \
    SERVERGAMEPORT="7777" \
    SERVERSTREAMING="true" \
    SKIPUPDATE="false" \
    STEAMAPPID="1690800" \
    STEAMBETA="false" \
    TIMEOUT="30" \
    VMOVERRIDE="false"

# hadolint ignore=DL3008
RUN set -x \
 && apt-get update \
 && apt-get install -y gosu xdg-user-dirs curl jq tzdata --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -g ${GID} steam \
 && useradd -u ${UID} -g ${GID} -ms /bin/bash steam \
 && mkdir -p /home/steam/.local/share/Steam/ \
 && cp -R /root/.local/share/Steam/steamcmd/ /home/steam/.local/share/Steam/steamcmd/ \
 && chown -R ${UID}:${GID} /home/steam/.local/ \
 && gosu nobody true

RUN mkdir -p /config \
 && chown steam:steam /config

COPY init.sh /
COPY --chown=steam:steam healthcheck.sh run.sh /home/steam/

HEALTHCHECK --timeout=30s --start-period=300s CMD bash /home/steam/healthcheck.sh

WORKDIR /config
ARG VERSION="DEV"
ENV VERSION=$VERSION
LABEL version=$VERSION
STOPSIGNAL SIGINT
EXPOSE 7777/udp 7777/tcp

ENTRYPOINT [ "/init.sh" ]