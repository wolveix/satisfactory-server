#!/bin/bash

set -e

# temporary addition as the game doesn't respect the config directory being within /config/gamefiles
GAMESAVESDIR="/home/steam/.config/Epic/FactoryGame/Saved/SaveGames"

mkdir -p /home/steam/config/backups /home/steam/config/gamefiles /home/steam/config/saves "${GAMECONFIGDIR}/Config/LinuxServer" "${GAMECONFIGDIR}/Logs" "${GAMECONFIGDIR}/SaveGames/server" "${GAMESAVESDIR}/server" || exit 1

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

/home/steam/steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/steam/config/gamefiles +app_update "$STEAMAPPID$STEAMBETAFLAG" +quit

cp -a /home/steam/config/saves/. /home/steam/config/backups/
cp -a "${GAMESAVESDIR}/server/." /home/steam/config/backups # useless in first run, but useful in additional runs
rm -rf "${GAMESAVESDIR}/server"
ln -sf /home/steam/config/saves "${GAMESAVESDIR}/server"
ln -sf /home/steam/config/ServerSettings.15777 "${GAMESAVESDIR}/ServerSettings.15777"

if [[ ! -f "/home/steam/config/Engine.ini" ]]; then
    cp /home/steam/Engine.ini /home/steam/config/Engine.ini || exit 1
fi

if [[ ! -f "/home/steam/config/Game.ini" ]]; then
    cp /home/steam/Game.ini /home/steam/config/Game.ini || exit 1
fi

if [[ ! -f "/home/steam/config/Scalability.ini" ]]; then
    cp /home/steam/Scalability.ini /home/steam/config/Scalability.ini || exit 1
fi

cp /home/steam/config/{Engine.ini,Game.ini,Scalability.ini} "${GAMECONFIGDIR}/SaveGames/server"

if [ ! -f "/home/steam/config/gamefiles/Engine/Binaries/Linux/UE4Server-Linux-Shipping" ]; then
    printf "Game binary is missing.\\n"
    exit 1
fi

cd /home/steam/config/gamefiles || exit 1

Engine/Binaries/Linux/UE4Server-Linux-Shipping FactoryGame -log -NoSteamClient -unattended
