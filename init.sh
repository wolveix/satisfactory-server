#!/bin/bash

set -e

GAMECONFIGDIR="/root/.wine/drive_c/users/root/Local Settings/Application Data/FactoryGame/Saved"

mkdir -p /config /config/gamefiles /config/savefiles /config/savefilebackups "${GAMECONFIGDIR}/SaveGames/common" || true

if [[ "${STEAMBETA}" == "true" ]]; then
    printf "Experimental flag is set. Experimental will be downloaded instead of Early Access.\\n"
    STEAMBETAFLAGS="-beta experimental"
fi

if [[ -z "${STEAMUSER}" || -z "${STEAMPWD}" || -z "${STEAMCODE}" ]]; then
    printf "Missing Steam credentials environment variables (STEAMUSER, STEAMPWD, STEAMCODE).\\n"
    exit 1
fi

steamcmd +@sSteamCmdForcePlatformType windows \
    +login "${STEAMUSER}" "${STEAMPWD}" "${STEAMCODE}" \
    +force_install_dir /config/gamefiles \
    +app_update "${STEAMAPPID}" ${STEAMBETAFLAGS} \
    +quit

cd /config/gamefiles || exit 1

if [[ ! -f "$GAMECONFIGDIR/Config/WindowsNoEditor/Engine.ini" || ! -f "$GAMECONFIGDIR/Config/WindowsNoEditor/Game.ini" ]]; then
    printf "\\nIt doesn't look like Satisfactory has been started before. Generating config files and inserting cron jobs.\\n"
    wine start FactoryGame.exe -nosteamclient -nullrhi -nosplash -nosound && sleep 5s

    pkill FactoryGame.exe

    echo "$(cat /root/Engine.ini)" >> "$GAMECONFIGDIR/Config/WindowsNoEditor/Engine.ini"
    echo "$(cat /root/Game.ini)" > "$GAMECONFIGDIR/Config/WindowsNoEditor/Game.ini" # this won't get created, so we don't append the echo.

    echo "*/30 * * * * cp -r \"${GAMECONFIGDIR}/SaveGames/common/\"*.sav /config/savefiles/ 2>&1
0 */6 * * * /backup.sh 2>&1" > cronjobs
    crontab cronjobs
    service cron start
fi

if [[ ! -f "/config/savefiles/savefile.sav" ]]; then
    printf "\\nSave file cannot be found. You need to generate a new world on your client, and then put it into /config/savefiles/savefile.sav\\n"
    exit 1
fi

cp -r /config/savefiles/*.sav "${GAMECONFIGDIR}"/SaveGames/common/
lastsavepath=$(find "${GAMECONFIGDIR}"/SaveGames/common -name '*.sav' -printf '%p\n' | sort -r | head -n 1)
lastsavefile=$(basename "$lastsavepath")
if [[ ! "${lastsavefile}" == "savefile.sav" ]]; then
    printf "\\nMoving most recent save (${lastsavefile}) to savefile.sav\\n"
    mv "${lastsavepath}" "${GAMECONFIGDIR}/SaveGames/common/savefile.sav"
fi

wine start FactoryGame.exe -nosteamclient -nullrhi -nosplash -nosound && \
tail -f "/root/.wine/drive_c/users/root/Local Settings/Application Data/FactoryGame/Saved/Logs/FactoryGame.log"