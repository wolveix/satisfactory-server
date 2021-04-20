#!/bin/bash

set -e

GAMECONFIGDIR="/root/.wine/drive_c/users/root/Local Settings/Application Data/FactoryGame/Saved"

mkdir -p /config/gamefiles /config/savefiles /config/savefilebackups "${GAMECONFIGDIR}/Config/WindowsNoEditor" "${GAMECONFIGDIR}/Logs" "${GAMECONFIGDIR}/SaveGames/common" || true
touch "${GAMECONFIGDIR}/Config/WindowsNoEditor/Engine.ini" "${GAMECONFIGDIR}/Config/WindowsNoEditor/Game.ini" "${GAMECONFIGDIR}/Logs/FactoryGame.log"

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

echo "$(cat /root/Engine.ini)" > "$GAMECONFIGDIR/Config/WindowsNoEditor/Engine.ini"
echo "$(cat /root/Game.ini)" > "$GAMECONFIGDIR/Config/WindowsNoEditor/Game.ini"

echo "*/5 * * * * cp -rp \"${GAMECONFIGDIR}/SaveGames/common/\"*.sav /config/savefiles/ 2>&1
0 */6 * * * /backup.sh 2>&1" > cronjobs
crontab cronjobs
service cron start

if [[ ! -f "/config/savefiles/savefile.sav" ]]; then
    printf "\\nSave file cannot be found. You need to generate a new world on your client, and then put it into /config/savefiles/savefile.sav\\n"
    exit 1
fi

cp -rp /config/savefiles/*.sav "${GAMECONFIGDIR}"/SaveGames/common/
lastsavefile=$(ls -Art "${GAMECONFIGDIR}"/SaveGames/common | tail -n 1)
if [[ ! "${lastsavefile}" == "savefile.sav" ]]; then
    printf "\\nMoving most recent save (${lastsavefile}) to savefile.sav\\n"
    mv "${GAMECONFIGDIR}"/SaveGames/common/"${lastsavefile}" "${GAMECONFIGDIR}/SaveGames/common/savefile.sav"
fi

wine start FactoryGame.exe -nosteamclient -nullrhi -nosplash -nosound && \
tail -f "${GAMECONFIGDIR}/Logs/FactoryGame.log"
