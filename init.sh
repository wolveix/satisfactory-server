#!/bin/bash

set -e

mkdir -p /config/gamefiles /config/saves "${GAMECONFIGDIR}/Config/WindowsNoEditor" "${GAMECONFIGDIR}/Logs" "${GAMECONFIGDIR}/SaveGames/common" || exit 1

if [[ "$STEAMBETA" == "true" ]]; then
    printf "Experimental flag is set. Experimental will be downloaded instead of Early Access.\\n"
    STEAMBETAFLAG=" -beta experimental"
fi

printf "Checking available space...\\n"
space=$(stat -f --format="%a*%S" .)
space=$((space/1024/1024/1024))

if [[ "$space" -lt 5 ]]; then
  printf "You have less than 5GB (${space}GB detected) of available space to download the game.\\nIf this is a fresh install, it will probably fail.\\n"
fi

printf "Downloading the latest version of the game...\\n"

/home/steam/steamcmd/steamcmd.sh +login anonymous +force_install_dir /config/gamefiles +app_update "$STEAMAPPID$STEAMBETAFLAG" +quit

cp -rp /config/saves/ "${GAMECONFIGDIR}/SaveGames/common/"

cd /config/gamefiles || exit 1

if [ ! -f "/config/gamefiles/FactoryServer.sh" ]; then
    printf "Game binary is missing.\\n"
    exit 1
fi

if [[ ! -f "/config/Engine.ini" ]]; then
    cp /home/steam/Engine.ini /config/Engine.ini || exit 1
fi

if [[ ! -f "/config/Game.ini" ]]; then
    cp /home/steam/Game.ini /config/Game.ini || exit 1
fi

if [[ ! -f "/config/Scalability.ini" ]]; then
    cp /home/steam/Scalability.ini /config/Scalability.ini || exit 1
fi

cp /config/{Engine.ini,Game.ini,Scalability.ini} "${GAMECONFIGDIR}/Config/LinuxServer/"

./FactoryServer.sh