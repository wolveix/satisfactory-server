#!/bin/bash

set -e

mkdir -p /config/gamefiles /config/savefiles /config/savefilebackups /config/steam /root/.steam/config "${GAMECONFIGDIR}/Config/WindowsNoEditor" "${GAMECONFIGDIR}/Logs" "${GAMECONFIGDIR}/SaveGames/common" || exit 1
touch "${GAMECONFIGDIR}/Logs/FactoryGame.log"

if [[ -z "$STEAMUSER" || -z "$STEAMPWD" ]]; then
    printf "Missing Steam credentials environment variables (STEAMUSER, STEAMPWD).\\n"
    exit 1
fi

sentry=$(find /config/steam/ -type f -name "ssfn*")

if [[ ! -f "/config/steam/config.vdf" || ! -f "$sentry" ]]; then
    if [[ -z "$STEAMCODE" ]]; then
        printf "Missing Steam credentials environment variables (STEAMCODE), this code is needed for the intial build.\\n"
        exit 1
    fi
else
    sentry_file=$(basename "$sentry")

    cp "/config/steam/config.vdf" "/root/.steam/config/config.vdf"
    cp "$sentry" "/root/.steam/${sentry_file}"
fi

if [[ "$STEAMBETA" == "true" ]]; then
    printf "Experimental flag is set. Experimental will be downloaded instead of Early Access.\\n"
    STEAMBETAFLAG=" -beta experimental"
fi

printf "Checking available space...\\n"
space=$(stat -f --format="%a*%S" .)
space=$((space/1024/1024/1024))

if [[ "$space" -lt 20 ]]; then
  printf "You have less than 20GB (${space}GB detected) of available space to download the game.\\nIf this is a fresh install, it will probably fail.\\n"
fi

printf "Downloading the latest version of the game...\\n"

export STEAMBETAFLAG
envsubst < "/steamscript.txt" > "/root/steamscript.txt"

steamcmd +runscript /root/steamscript.txt
errors=$(< /root/.steam/logs/connection_log.txt grep "Invalid" || true)
if [[ -n "$errors" ]]; then
    printf "Failed to login to Steam. Please check your Steam credentials.\\nSleeping for 60 seconds..."
    sleep 60
    exit 1
fi

rm /root/steamscript.txt

sentry=$(find /root/.steam/ -type f -name "ssfn*")
if [[ -n "$sentry" ]]; then
    cp "$sentry" /config/steam/
fi

if [[ -f "/root/.steam/config/config.vdf" ]]; then
    cp /root/.steam/config/config.vdf /config/steam/
fi

echo "*/5 * * * * cp -rp \"${GAMECONFIGDIR}/SaveGames/common/\"*.sav /config/savefiles/ 2>&1
0 */6 * * * /backup.sh 2>&1" > cronjobs
crontab cronjobs
service cron start
rm cronjobs

cd /config/gamefiles || exit 1

if [[ ! -f "FactoryGame.exe" ]]; then
    printf "Game binary is missing.\\n"
    exit 1
fi

if [[ ! -f "/config/Engine.ini" ]]; then
    cp /home/satisfactory/Engine.ini /config/Engine.ini || exit 1
fi

if [[ ! -f "/config/Game.ini" ]]; then
    cp /home/satisfactory/Game.ini /config/Game.ini || exit 1
fi

if [[ ! -f "/config/Scalability.ini" ]]; then
    cp /home/satisfactory/Scalability.ini /config/Scalability.ini || exit 1
fi

cp /config/{Engine.ini,Game.ini,Scalability.ini} "$GAMECONFIGDIR/Config/WindowsNoEditor/"

if [[ -f "${GAMECONFIGDIR}/SaveGames/common/*.sav" ]]; then
    rm "${GAMECONFIGDIR}/SaveGames/common/*.sav"
fi

cp -rp /config/savefiles/*.sav "${GAMECONFIGDIR}"/SaveGames/common/
lastsavefile=$(ls -Art "${GAMECONFIGDIR}"/SaveGames/common | tail -n 1)
if [[ ! "${lastsavefile}" == "savefile.sav" ]]; then
    printf "\\nMoving most recent save (%s) to savefile.sav\\n" "$lastsavefile"
    mv "${GAMECONFIGDIR}"/SaveGames/common/"${lastsavefile}" "${GAMECONFIGDIR}/SaveGames/common/savefile.sav"
fi

if [[ ! -f "${GAMECONFIGDIR}/SaveGames/common/savefile.sav" ]]; then
    printf "\\nSave file cannot be found. You need to generate a new world on your client, and then put it into /config/savefiles/\\n"
    exit 1
fi

chown -R satisfactory:satisfactory /config/gamefiles /home/satisfactory
chown root:root "$GAMECONFIGDIR/Config/WindowsNoEditor/Engine.ini" "$GAMECONFIGDIR/Config/WindowsNoEditor/Game.ini"

sudo -u satisfactory -H sh -c "wine start FactoryGame.exe -listen -nosteamclient -nosplash -nosound -nullrhi -server -spectatoronly -unattended"

tail -f "${GAMECONFIGDIR}/Logs/FactoryGame.log"