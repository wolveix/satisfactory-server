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

if [[ "$MULTIHOME" != "::" ]]; then
    # Check if it's a valid IPv4 address (0-255 segments).
    if [[ "$MULTIHOME" =~ ^(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]; then
        printf "Accepting IPv4 connections only on %s\n" "$MULTIHOME"
    # Basic IPv6 validation, allowing shorthand (some invalid ones may still pass here).
    elif [[ "$MULTIHOME" =~ ^(([0-9a-fA-F]{0,4}::?){0,7})([0-9a-fA-F]{1,4})(::)?$ ]]; then
        printf "Trying to accept IPv6 connections only on %s\n" "$MULTIHOME"
    else
        printf "\e[31mInvalid IP address given: %s\e[0m\n" "$MULTIHOME"
    fi

    printf "Testing given Interface: " # Should always be reachable since localhost, practically checks if interface exists
    if ping -c 1 "$MULTIHOME"; then
        printf "\e[32mValid and reachable: %s\e[0m\n" "$MULTIHOME" 
    else
        printf "\e[31mInvalid or unreachable: %s\e[0m\n" "$MULTIHOME"
        exit 1 # Fail LOUDLY as to prevent the need to dig through the log
    fi
fi

# Secondary check needed if a failure condition occurs above.
if [[ "$MULTIHOME" == "::" ]]; then
    printf "Multihome will accept IPv4 and IPv6 connections\\n"
fi

printf "Setting multihome to %s\\n" "$MULTIHOME"

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
  "-multihome=$MULTIHOME"
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
cp -r "${GAMESAVESDIR}/server/." "/config/backups" # useful after the first run
rm -rf "$GAMESAVESDIR"
ln -sf "/config/saved" "$GAMESAVESDIR"

if [ ! -f "/config/gamefiles/FactoryServer.sh" ]; then
    printf "FactoryServer launch script is missing.\\n"
    exit 1
fi

cd /config/gamefiles || exit 1

chmod +x FactoryServer.sh || true
./FactoryServer.sh -Port="$SERVERGAMEPORT" "${ini_args[@]}" "$@" &

sleep 2
satisfactory_pid=$(ps --ppid ${!} o pid=)

shutdown() {
    printf "\\nReceived SIGINT. Shutting down.\\n"
    kill -INT $satisfactory_pid 2>/dev/null
}
trap shutdown SIGINT SIGTERM

wait
