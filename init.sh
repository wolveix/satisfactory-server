#!/bin/bash

set -e

if [[ "$DEBUG" == "true" ]]; then
    printf "Debugging enabled (the container will exit after printing the debug info)\\n\\nPrinting environment variables:\\n"
    export

    printf "\\n\\nDisk usage:\\n"
    df -h | awk '$NF=="/"{printf "%d/%dGB (%s)\n", $3,$2,$5}'
    
    printf "\\nCurent user:\\n"
    id

    printf "\\nExiting...\\n"
    exit 1
fi

mkdir -p /config/backups /config/gamefiles /config/saves "${GAMECONFIGDIR}/Config/LinuxServer" "${GAMECONFIGDIR}/Logs" "${GAMECONFIGDIR}/SaveGames/server" "${GAMESAVESDIR}/server" || exit 1

NUMCHECK='^[0-9]+$'

if ! [[ "$PGID" =~ $NUMCHECK ]] ; then
    printf "Invalid group id given: ${PGID}\\n"
    PGID="1000"
fi

if ! [[ "$PUID" =~ $NUMCHECK ]] ; then
    printf "Invalid user id given: ${PUID}\\n"
    PUID="1000"
fi

groupmod -g "${PGID}" steam || exit 1
usermod -u "${PUID}" steam || exit 1

chown -R steam:steam /config /home/steam

sudo -u steam -E -H sh -c "/home/steam/run.sh"