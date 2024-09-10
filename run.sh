#!/bin/bash

set -e

set_ini_prop() {
    sed "/\[$2\]/,/^\[/ s/$3\=.*/$3=$4/" -i "/home/steam/$1"
}

set_ini_val() {
    sed "s/\(\"$2\", \)[0-9]*/\1$3/" -i "/home/steam/$1"
}

if [ -f "/config/overrides/Engine.ini" ]; then
    echo "Config override /config/overrides/Engine.ini exists, ignoring environment variables"
    cp /config/overrides/Engine.ini "${GAMECONFIGDIR}/Config/LinuxServer/"
else
    if ! [[ "$MAXOBJECTS" =~ $NUMCHECK ]] ; then
        printf "Invalid max objects number given: %s\\n" "$MAXOBJECTS"
        MAXOBJECTS="2162688"
    fi
    printf "Setting max objects number to %s\\n" "$MAXOBJECTS"
    set_ini_prop "Engine.ini" "\/Script\/Engine\.GarbageCollectionSettings" "gc.MaxObjectsInEditor" "$MAXOBJECTS"
    set_ini_prop "Engine.ini" "\/Script\/Engine\.GarbageCollectionSettings" "gc.MaxObjectsInGame" "$MAXOBJECTS"

    if ! [[ "$MAXTICKRATE" =~ $NUMCHECK ]] ; then
        printf "Invalid max tick rate number given: %s\\n" "$MAXTICKRATE"
        MAXTICKRATE="120"
    fi
    printf "Setting max tick rate to %s\\n" "$MAXTICKRATE"
    set_ini_prop "Engine.ini" "\/Script\/OnlineSubsystemUtils.IpNetDriver" "NetServerMaxTickRate" "$MAXTICKRATE"
    set_ini_prop "Engine.ini" "\/Script\/OnlineSubsystemUtils.IpNetDriver" "LanServerMaxTickRate" "$MAXTICKRATE"

    if ! [[ "$TIMEOUT" =~ $NUMCHECK ]] ; then
        printf "Invalid timeout number given: %s\\n" "$TIMEOUT"
        TIMEOUT="300"
    fi
    printf "Setting timeout number to %s\\n" "$TIMEOUT"
    set_ini_prop "Engine.ini" "\/Script\/OnlineSubsystemUtils\.IpNetDriver" "ConnectionTimeout" "$TIMEOUT"
    set_ini_prop "Engine.ini" "\/Script\/OnlineSubsystemUtils\.IpNetDriver" "InitialConnectTimeout" "$TIMEOUT"

    [[ "${SERVERSTREAMING,,}" == "true" ]] && SERVERSTREAMING="1" || SERVERSTREAMING="0"
    printf "Setting server streaming to %s\\n" "$SERVERSTREAMING"
    set_ini_prop "Engine.ini" "ConsoleVariables" "wp.Runtime.EnableServerStreaming" "$SERVERSTREAMING"

    cp /home/steam/Engine.ini "${GAMECONFIGDIR}/Config/LinuxServer/"
fi

if [ -f "/config/overrides/Game.ini" ]; then
    echo "Config override /config/overrides/Game.ini exists, ignoring environment variables"
    cp /config/overrides/Game.ini "${GAMECONFIGDIR}/Config/LinuxServer/"
else
    if ! [[ "$TIMEOUT" =~ $NUMCHECK ]] ; then
        printf "Invalid timeout number given: %s\\n" "$TIMEOUT"
        TIMEOUT="300"
    fi
    printf "Setting timeout number to %s\\n" "$TIMEOUT"
    set_ini_prop "Game.ini" "\/Script\/Engine\.GameSession" "ConnectionTimeout" "$TIMEOUT"
    set_ini_prop "Game.ini" "\/Script\/Engine\.GameSession" "InitialConnectTimeout" "$TIMEOUT"

    if ! [[ "$MAXPLAYERS" =~ $NUMCHECK ]] ; then
        printf "Invalid max players given: %s\\n" "$MAXPLAYERS"
        MAXPLAYERS="4"
    fi
    printf "Setting max players to %s\\n" "$MAXPLAYERS"
    set_ini_prop "Game.ini" "\/Script\/Engine\.GameSession" "MaxPlayers" "$MAXPLAYERS"

    cp /home/steam/Game.ini "${GAMECONFIGDIR}/Config/LinuxServer/"
fi

if [ -f "/config/overrides/GameUserSettings.ini" ]; then
    echo "Config override /config/overrides/GameUserSettings.ini exists, ignoring environment variables"
    cp /config/overrides/GameUserSettings.ini "${GAMECONFIGDIR}/Config/LinuxServer/"
else
    [[ "${DISABLESEASONALEVENTS,,}" == "true" ]] && DISABLESEASONALEVENTS="1" || DISABLESEASONALEVENTS="0"
    printf "Setting disable seasonal events to %s\\n" "$DISABLESEASONALEVENTS"
    set_ini_val "GameUserSettings.ini" "FG.DisableSeasonalEvents" "$DISABLESEASONALEVENTS"

    cp /home/steam/GameUserSettings.ini "${GAMECONFIGDIR}/Config/LinuxServer/"
fi

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
    printf "Checking available storage...%sGB detected\\n" "$STORAGEAVAILABLE"

    if [[ "$STORAGEAVAILABLE" -lt 8 ]]; then
        printf "You have less than 8GB (%sGB detected) of available storage to download the game.\\nIf this is a fresh install, it will probably fail.\\n" "$STORAGEAVAILABLE"
    fi

    printf "Downloading the latest version of the game...\\n"
    steamcmd +force_install_dir /config/gamefiles +login anonymous +app_update "$STEAMAPPID" -beta "$STEAMBETAFLAG" validate +quit
else
    printf "Skipping update as flag is set\\n"
fi

cp -r "/config/saved/server/." "/config/backups/"
cp -r "${GAMESAVESDIR}/server/." "/config/backups" # useful after the first run
rm -rf "$GAMESAVESDIR"
ln -sf "/config/saved" "$GAMESAVESDIR"

if [ ! -f "/config/gamefiles/FactoryServer.sh" ]; then
    printf "FactoryServer launch script is missing.\\n"
    exit 1
fi

cd /config/gamefiles || exit 1

exec ./FactoryServer.sh -Port="$SERVERGAMEPORT" "$@"