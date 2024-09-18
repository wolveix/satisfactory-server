#!/bin/bash

set -e

# Engine.ini settings
if ! [[ "$AUTOSAVENUM" =~ $NUMCHECK ]]; then
    printf "Invalid autosave number given: %s\\n" "$AUTOSAVENUM"
    AUTOSAVENUM="5"
fi
printf "Setting autosave number to %s\\n" "$AUTOSAVENUM"

if ! [[ "$MAXOBJECTS" =~ $NUMCHECK ]]; then
    printf "Invalid max objects number given: %s\\n" "$MAXOBJECTS"
    MAXOBJECTS="2162688"
fi
printf "Setting max objects to %s\\n" "$MAXOBJECTS"

if ! [[ "$MAXTICKRATE" =~ $NUMCHECK ]] ; then
    printf "Invalid max tick rate number given: %s\\n" "$MAXTICKRATE"
    MAXTICKRATE="120"
fi
printf "Setting max tick rate to %s\\n" "$MAXTICKRATE"

[[ "${SERVERSTREAMING,,}" == "true" ]] && SERVERSTREAMING="1" || SERVERSTREAMING="0"
printf "Setting server streaming to %s\\n" "$SERVERSTREAMING"

if ! [[ "$TIMEOUT" =~ $NUMCHECK ]] ; then
    printf "Invalid timeout number given: %s\\n" "$TIMEOUT"
    TIMEOUT="300"
fi
printf "Setting timeout to %s\\n" "$TIMEOUT"

# Game.ini settings
if ! [[ "$MAXPLAYERS" =~ $NUMCHECK ]] ; then
    printf "Invalid max players given: %s\\n" "$MAXPLAYERS"
    MAXPLAYERS="4"
fi
printf "Setting max players to %s\\n" "$MAXPLAYERS"

# GameUserSettings.ini settings
if [[ "${DISABLESEASONALEVENTS,,}" == "true" ]]; then
    printf "Disabling seasonal events\\n"
    DISABLESEASONALEVENTS="-DisableSeasonalEvents"
else
    DISABLESEASONALEVENTS=""
fi

ini_args=(
  "-ini:Engine:[Core.Log]:LogNet=Error"
  "-ini:Engine:[Core.Log]:LogNetTraffic=Warning"
  "-ini:Engine:[/Script/FactoryGame.FGSaveSession]:mNumRotatingAutosaves=$AUTOSAVENUM"
  "-ini:Engine:[/Script/Engine.GarbageCollectionSettings]:gc.MaxObjectsInEditor=$MAXOBJECTS"
  "-ini:Engine:[/Script/OnlineSubsystemUtils.IpNetDriver]:LanServerMaxTickRate=$MAXTICKRATE"
  "-ini:Engine:[/Script/OnlineSubsystemUtils.IpNetDriver]:NetServerMaxTickRate=$MAXTICKRATE"
  "-ini:Engine:[/Script/OnlineSubsystemUtils.IpNetDriver]:ConnectionTimeout=$TIMEOUT"
  "-ini:Engine:[/Script/OnlineSubsystemUtils.IpNetDriver]:InitialConnectTimeout=$TIMEOUT"
  "-ini:Engine:[ConsoleVariables]:wp.Runtime.EnableServerStreaming=$SERVERSTREAMING"
  "-ini:Game:[/Script/Engine.GameSession]:ConnectionTimeout=$TIMEOUT"
  "-ini:Game:[/Script/Engine.GameSession]:InitialConnectTimeout=$TIMEOUT"
  "-ini:Game:[/Script/Engine.GameSession]:MaxPlayers=$MAXPLAYERS"
  "-ini:GameUserSettings:[/Script/Engine.GameSession]:MaxPlayers=$MAXPLAYERS"
  "$DISABLESEASONALEVENTS"
)

if [[ "${SKIPUPDATE,,}" != "false" ]] && [ ! -f "/config/gamefiles/FactoryServer.sh" ]; then
    printf "%s Skip update is set, but no game files exist. Updating anyway\\n" "${MSGWARNING}"
    SKIPUPDATE="false"
fi

if [[ "${SKIPUPDATE,,}" != "true" ]]; then
    if [[ "${STEAMBETA,,}" == "true" ]]; then
        printf "Experimental flag is set. Experimental will be downloaded instead of Early Access.\\n"
        STEAMBETAFLAG="experimental"
    else
        STEAMBETAFLAG="public"
    fi

    STORAGEAVAILABLE=$(stat -f -c "%a*%S" .)
    STORAGEAVAILABLE=$((STORAGEAVAILABLE/1024/1024/1024))
    printf "Checking available storage: %sGB detected\\n" "$STORAGEAVAILABLE"

    if [[ "$STORAGEAVAILABLE" -lt 8 ]]; then
        printf "You have less than 8GB (%sGB detected) of available storage to download the game.\\nIf this is a fresh install, it will probably fail.\\n" "$STORAGEAVAILABLE"
    fi

    printf "\\nDownloading the latest version of the game...\\n"
    steamcmd +force_install_dir /config/gamefiles +login anonymous +app_update "$STEAMAPPID" -beta "$STEAMBETAFLAG" validate +quit
    cp -r /home/steam/.steam/steam/logs/* "/config/logs/steam" || printf "Failed to store Steam logs\\n"
else
    printf "Skipping update as flag is set\\n"
fi

printf "Launching game server\\n\\n"

cp -r "/config/saved/server/." "/config/backups/"
cp -r "${GAMESAVESDIR}/server/." "/config/backups" # useful after the first run
rm -rf "$GAMESAVESDIR"
ln -sf "/config/saved" "$GAMESAVESDIR"

if [ ! -f "/config/gamefiles/FactoryServer.sh" ]; then
    printf "FactoryServer launch script is missing.\\n"
    exit 1
fi

cd /config/gamefiles || exit 1

chmod +x FactoryServer.sh
./FactoryServer.sh -Port="$SERVERGAMEPORT" "${ini_args[@]}" "$@" &

sleep 2
satisfactory_pid=$(ps --ppid ${!} o pid=)

shutdown() {
    printf "\\nReceived SIGINT. Shutting down.\\n"
    kill -INT $satisfactory_pid 2>/dev/null
}
trap shutdown SIGINT SIGTERM

wait
