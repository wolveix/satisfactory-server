#!/bin/bash

set -e

NUMCHECK='^[0-9]+$'

if ! [[ "$MAXPLAYERS" =~ $NUMCHECK ]] ; then
    printf "Invalid max players given: ${MAXPLAYERS}\\n"
    MAXPLAYERS="16"
fi

printf "Setting max players to ${MAXPLAYERS}\\n"
sed "s/MaxPlayers\=16/MaxPlayers=$MAXPLAYERS/" -i "/home/steam/Game.ini"

if [[ "$SKIPUPDATE" == "false" ]]; then
    if [[ "$STEAMBETA" == "true" ]]; then
        printf "Experimental flag is set. Experimental will be downloaded instead of Early Access.\\n"
        STEAMBETAFLAG=" -beta experimental"
    fi

    space=$(stat -f --format="%a*%S" .)
    space=$((space/1024/1024/1024))
    printf "Checking available space...${space}GB detected\\n"

    if [[ "$space" -lt 5 ]]; then
        printf "You have less than 5GB (${space}GB detected) of available space to download the game.\\nIf this is a fresh install, it will probably fail.\\n"
    fi

    printf "Downloading the latest version of the game...\\n"

    /home/steam/steamcmd/steamcmd.sh +login anonymous +force_install_dir /config/gamefiles +app_update "$STEAMAPPID$STEAMBETAFLAG" +quit
else
    printf "Skipping update as flag is set\\n"
fi

cp -a /config/saves/. /config/backups/
cp -a "${GAMESAVESDIR}/server/." /config/backups # useless in first run, but useful in additional runs
rm -rf "${GAMESAVESDIR}/server"
ln -sf /config/saves "${GAMESAVESDIR}/server"

cp /home/steam/{Engine.ini,Game.ini,Scalability.ini} "${GAMECONFIGDIR}/Config/LinuxServer"

if [ ! -f "/config/gamefiles/Engine/Binaries/Linux/UE4Server-Linux-Shipping" ]; then
    printf "Game binary is missing.\\n"
    exit 1
fi

cd /config/gamefiles || exit 1

Engine/Binaries/Linux/UE4Server-Linux-Shipping FactoryGame -log -NoSteamClient -unattended