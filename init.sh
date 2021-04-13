#!/bin/bash

set -e

GAMECONFIGDIR="/root/.wine/drive_c/users/root/Local Settings/Application Data/FactoryGame/Saved"

mkdir -p /config /config/gamefiles /config/savefiles "${GAMECONFIGDIR}/SaveGames/common" || true

if [[ -z "${STEAMUSER}" || -z "${STEAMPWD}" || -z "${STEAMCODE}" ]]; then
    printf "Missing Steam credentials environment variables (STEAMUSER, STEAMPWD, STEAMCODE).\\n"
    exit 1
fi

steamcmd +@sSteamCmdForcePlatformType windows \
    +login "${STEAMUSER}" "${STEAMPWD}" "${STEAMCODE}" \
    +force_install_dir /config/gamefiles \
    +app_update "${STEAMAPPID}" \
    +quit

cd /config/gamefiles || exit 1

if [[ ! -f "$GAMECONFIGDIR/Config/WindowsNoEditor/Engine.ini" || ! -f "$GAMECONFIGDIR/Config/WindowsNoEditor/Game.ini" ]]; then
    printf "\\nIt doesn't look like Satisfactory has been started before. Launching it for a few seconds to generate config files.\\n"
    wine start FactoryGame.exe -nosteamclient -nullrhi -nosplash -nosound &
    sleep 5s

    pkill FactoryGame.exe

    echo "[/Script/Engine.GameNetworkManager]
    TotalNetBandwidth=104857600
    MinDynamicBandwidth=10485760
    MaxDynamicBandwidth=104857600

    [/Script/Engine.GameSession]
    MaxPlayers=8" >> "$GAMECONFIGDIR/Config/WindowsNoEditor/Game.ini"

    echo "[/Script/EngineSettings.GameMapsSettings]
    GameDefaultMap=/Game/FactoryGame/Map/GameLevel01/Persistent_Level
    LocalMapOptions=?sessionName=savefile?Visibility=SV_FriendsOnly?loadgame=savefile?listen?bUseIpSockets?name=Host

    [/Script/Engine.Player]
    ConfiguredInternetSpeed=104857600
    ConfiguredLanSpeed=104857600

    [/Script/OnlineSubsystemUtils.IpNetDriver]
    NetServerMaxTickRate=120
    MaxNetTickRate=400
    MaxInternetClientRate=104857600
    MaxClientRate=104857600
    LanServerMaxTickRate=120
    InitialConnectTimeout=300.0
    ConnectionTimeout=300.0

    [/Script/SocketSubsystemEpic.EpicNetDriver]
    MaxClientRate=104857600
    MaxInternetClientRate=104857600" >> "$GAMECONFIGDIR/Config/WindowsNoEditor/Engine.ini"
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

echo "*/30 * * * * cp -r \"${GAMECONFIGDIR}/SaveGames/common/\"*.sav /config/savefiles/ 2>&1" > cronjobs
crontab cronjobs

wine start FactoryGame.exe -nosteamclient -nullrhi -nosplash -nosound && \
tail -f "/root/.wine/drive_c/users/root/Local Settings/Application Data/FactoryGame/Saved/Logs/FactoryGame.log"