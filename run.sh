#!/bin/bash

set -e

# Port validation
if ! [[ "$SERVERGAMEPORT" =~ $NUMCHECK ]]; then
    printf "Invalid server port given: %s\\n" "$SERVERGAMEPORT"
    SERVERGAMEPORT="7777"
fi
printf "Setting server port to %s\\n" "$SERVERGAMEPORT"

if ! [[ "$SERVERMESSAGINGPORT" =~ $NUMCHECK ]]; then
    printf "Invalid messaging port given: %s\\n" "$SERVERMESSAGINGPORT"
    SERVERMESSAGINGPORT="8888"
fi
printf "Setting messaging port to %s\\n" "$SERVERMESSAGINGPORT"

# Engine.ini settings.
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
    MAXTICKRATE="30"
fi
printf "Setting max tick rate to %s\\n" "$MAXTICKRATE"

[[ "${SERVERSTREAMING,,}" == "true" ]] && SERVERSTREAMING="1" || SERVERSTREAMING="0"
printf "Setting server streaming to %s\\n" "$SERVERSTREAMING"

if ! [[ "$TIMEOUT" =~ $NUMCHECK ]] ; then
    printf "Invalid timeout number given: %s\\n" "$TIMEOUT"
    TIMEOUT="30"
fi
printf "Setting timeout to %s\\n" "$TIMEOUT"

# Game.ini settings.
if ! [[ "$MAXPLAYERS" =~ $NUMCHECK ]] ; then
    printf "Invalid max players given: %s\\n" "$MAXPLAYERS"
    MAXPLAYERS="4"
fi
printf "Setting max players to %s\\n" "$MAXPLAYERS"

# GameUserSettings.ini settings.
if [[ "${DISABLESEASONALEVENTS,,}" == "true" ]]; then
    printf "Disabling seasonal events\\n"
    DISABLESEASONALEVENTS="-DisableSeasonalEvents"
else
    DISABLESEASONALEVENTS=""
fi

# Validate and set multihome address for network connections (useful for v6-only networks).
if [[ "$MULTIHOME" != "" ]]; then
    if [[ "$MULTIHOME" != "" ]] && [[ "$MULTIHOME" != "::" ]]; then
        # IPv4 regex matches addresses from 0.0.0.0 to 255.255.255.255.
        IPv4='^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$'

        # IPv6 regex supports full and shortened formats like 2001:db8::1.
        IPv6='^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))$'

        if [[ "$MULTIHOME" =~ $IPv4 ]]; then
            printf "Multihome will accept IPv4 connections only\n"
        elif [[ "$MULTIHOME" =~ $IPv6 ]]; then
            printf "Multihome will accept IPv6 connections only\n"
        else
            printf "Invalid multihome address: %s (defaulting to ::)\n" "$MULTIHOME"
            MULTIHOME="::"
        fi
    fi

    if [[ "$MULTIHOME" == "::" ]]; then
        printf "Multihome will accept IPv4 and IPv6 connections\n"
    fi

    printf "Setting multihome to %s\n" "$MULTIHOME"
    MULTIHOME="-multihome=$MULTIHOME"
fi

ini_args=(
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
  "$MULTIHOME"
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
    if [ -f "/config/gamefiles/steamapps/appmanifest_1690800.acf" ]; then
        printf "\\nRemoving the app manifest to force Steam to check for an update...\\n"
        rm "/config/gamefiles/steamapps/appmanifest_1690800.acf" || true
    fi
    steamcmd +force_install_dir /config/gamefiles +login anonymous +app_update "$STEAMAPPID" -beta "$STEAMBETAFLAG" validate +quit
    cp -r /home/steam/.steam/steam/logs/* "/config/logs/steam" || printf "Failed to store Steam logs\\n"
else
    printf "Skipping update as flag is set\\n"
fi

printf "Launching game server\\n\\n"

cp -r "/config/saved/server/." "/config/backups/"
cp -r "${GAMESAVESDIR}/server/." "/config/backups" # Useful after the first run.
rm -rf "$GAMESAVESDIR"
ln -sf "/config/saved" "$GAMESAVESDIR"

if [ ! -f "/config/gamefiles/FactoryServer.sh" ]; then
    printf "FactoryServer launch script is missing.\\n"
    exit 1
fi

cd /config/gamefiles || exit 1

chmod +x FactoryServer.sh || true
./FactoryServer.sh -Port="$SERVERGAMEPORT" -ReliablePort="$SERVERMESSAGINGPORT" -ExternalReliablePort="$SERVERMESSAGINGPORT" "${ini_args[@]}" "$@" &

sleep 2
satisfactory_pid=$(ps --ppid ${!} o pid=)

shutdown() {
    printf "\\nReceived SIGINT. Shutting down.\\n"
    kill -INT $satisfactory_pid 2>/dev/null
}
trap shutdown SIGINT SIGTERM

wait