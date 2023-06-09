#!/bin/bash

set -e

set_ini_prop() {
    sed "/\[$2\]/,/^\[/ s/$3\=.*/$3=$4/" -i "/home/steam/$1"
}

set_ini_val() {
    sed "s/\(\"$2\", \)[0-9]*/\1$3/" -i "/home/steam/$1"
}

NUMCHECK='^[0-9]+$'

## START Engine.ini
if ! [[ "$AUTOSAVENUM" =~ $NUMCHECK ]] ; then
    printf "Invalid autosave number given: %s\\n" "$AUTOSAVENUM"
    AUTOSAVENUM="3"
fi
printf "Setting autosave number to %s\\n" "$AUTOSAVENUM"
set_ini_prop "Engine.ini" "\/Script\/FactoryGame\.FGSaveSession" "mNumRotatingAutosaves" "$AUTOSAVENUM"

[[ "${CRASHREPORT,,}" == "true" ]] && CRASHREPORT="true" || CRASHREPORT="false"
printf "Setting crash reporting to %s\\n" "${CRASHREPORT^}"
set_ini_prop "Engine.ini" "CrashReportClient" "bImplicitSend" "${CRASHREPORT^}"

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
## END Engine.ini

## START Game.ini
# Finish setting timeout from Engine.ini
set_ini_prop "Game.ini" "\/Script\/Engine\.GameSession" "ConnectionTimeout" "$TIMEOUT"
set_ini_prop "Game.ini" "\/Script\/Engine\.GameSession" "InitialConnectTimeout" "$TIMEOUT"

if ! [[ "$MAXPLAYERS" =~ $NUMCHECK ]] ; then
    printf "Invalid max players given: %s\\n" "$MAXPLAYERS"
    MAXPLAYERS="4"
fi
printf "Setting max players to %s\\n" "$MAXPLAYERS"
set_ini_prop "Game.ini" "\/Script\/Engine\.GameSession" "MaxPlayers" "$MAXPLAYERS"
## END Game.ini

## START GameUserSettings.ini
if ! [[ "$AUTOSAVEINTERVAL" =~ $NUMCHECK ]] ; then
    printf "Invalid autosave interval given: %s\\n" "$AUTOSAVEINTERVAL"
    AUTOSAVEINTERVAL="300"
fi
printf "Setting autosave interval to %ss\\n" "$AUTOSAVEINTERVAL"
set_ini_val "GameUserSettings.ini" "FG.AutosaveInterval" "$AUTOSAVEINTERVAL"

[[ "${DISABLESEASONALEVENTS,,}" == "true" ]] && DISABLESEASONALEVENTS="1" || DISABLESEASONALEVENTS="0"
printf "Setting disable seasonal events to %s\\n" "$DISABLESEASONALEVENTS"
set_ini_val "GameUserSettings.ini" "FG.DisableSeasonalEvents" "$DISABLESEASONALEVENTS"

if ! [[ "$NETWORKQUALITY" =~ $NUMCHECK ]] ; then
    printf "Invalid network quality number given: %s\\n" "$NETWORKQUALITY"
    NETWORKQUALITY="3"
fi
printf "Setting network quality number to %s\\n" "$NETWORKQUALITY"
set_ini_prop "GameUserSettings.ini" "\/Script\/FactoryGame\.FGGameUserSettings" "mNetworkQuality" "$NETWORKQUALITY"
set_ini_val "GameUserSettings.ini" "FG.NetworkQuality" "$NETWORKQUALITY"
## END GameUserSettings.ini

## START ServerSettings.ini
[[ "${AUTOPAUSE,,}" == "true" ]] && AUTOPAUSE="true" || AUTOPAUSE="false"
printf "Setting auto pause to %s\\n" "${AUTOPAUSE^}"
set_ini_prop "ServerSettings.ini" "\/Script\/FactoryGame\.FGServerSubsystem" "mAutoPause" "${AUTOPAUSE^}"

[[ "${AUTOSAVEONDISCONNECT,,}" == "true" ]] && AUTOSAVEONDISCONNECT="true" || AUTOSAVEONDISCONNECT="false"
printf "Setting autosave on disconnect to %s\\n" "${AUTOSAVEONDISCONNECT^}"
set_ini_prop "ServerSettings.ini" "\/Script\/FactoryGame\.FGServerSubsystem" "mAutoSaveOnDisconnect" "${AUTOSAVEONDISCONNECT^}"
## END ServerSettings.ini

if ! [[ "${SKIPUPDATE,,}" == "true" ]]; then
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

# temporary migration to new format
if [ -d "/config/blueprints" ]; then
  if [ -n "$(ls -A "/config/blueprints" 2>/dev/null)" ]; then
    rm -rf "/config/saved/blueprints"
    mv "/config/blueprints" "/config/saved/blueprints"
  else
    rm -rf "/config/blueprints"
  fi
fi

if [ -d "/config/saves" ]; then
  if [ -n "$(ls -A "/config/saves" 2>/dev/null)" ]; then
    find "/config/saves/" -type f -print0 | xargs -0 mv -t "/config/saved/server" || exit 1
  else
    rmdir "/config/saves"
  fi
fi

if [ -f "/config/ServerSettings.${SERVERQUERYPORT}" ]; then
  mv "/config/ServerSettings.${SERVERQUERYPORT}" "/config/saved/ServerSettings.${SERVERQUERYPORT}"
fi
# temporary migration to new format

cp -r "/config/saved/server/." "/config/backups/"
cp -r "${GAMESAVESDIR}/server/." "/config/backups" # useful after the first run
rm -rf "$GAMESAVESDIR"
ln -sf "/config/saved" "$GAMESAVESDIR"
cp /home/steam/*.ini "${GAMECONFIGDIR}/Config/LinuxServer/"

if [ ! -f "/config/gamefiles/FactoryServer.sh" ]; then
    printf "FactoryServer launch script is missing.\\n"
    exit 1
fi

cd /config/gamefiles || exit 1

exec ./FactoryServer.sh -log -NoSteamClient -unattended ?listen -Port="$SERVERGAMEPORT" -BeaconPort="$SERVERBEACONPORT" -ServerQueryPort="$SERVERQUERYPORT" -multihome="$SERVERIP" "$@"
