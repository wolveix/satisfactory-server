FROM steamcmd/steamcmd:ubuntu-22

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
    PGID="1000" \
    PUID="1000" \
    ROOTLESS="false" \
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
 && useradd -ms /bin/bash steam \
 && gosu nobody true

RUN mkdir -p /config \
 && chown steam:steam /config

COPY init.sh healthcheck.sh /
COPY --chown=steam:steam run.sh /home/steam/

HEALTHCHECK --timeout=10s --start-period=180s \
  CMD bash /healthcheck.sh

WORKDIR /config

ARG VERSION="DEV"
ENV VERSION=$VERSION
LABEL version=$VERSION

STOPSIGNAL SIGINT

EXPOSE 7777/udp 7777/tcp

ENTRYPOINT [ "/init.sh" ]