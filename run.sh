#!/bin/bash

set -e

setiniprop() {
    sed "/\[$2\]/,/^\[/ s/$3\=.*/$3=$4/" -i "/home/steam/$1"
}

setinival() {
    sed "/\[$2\]/,/^\[/ s/((\"$3\",.*))/((\"$3\", $4))/" -i "/home/steam/$1"
}

NUMCHECK='^[0-9]+$'

## Game.ini
if ! [[ "$MAXPLAYERS" =~ $NUMCHECK ]] ; then
    printf "Invalid max players given: %s\\n" "${MAXPLAYERS}"
    MAXPLAYERS="4"
fi
printf "Setting max players to %s\\n" "${MAXPLAYERS}"
setiniprop "Game.ini" "\/Script\/Engine\.GameSession" "MaxPlayers" "${MAXPLAYERS}"

## Engine.ini
if ! [[ "$AUTOSAVENUM" =~ $NUMCHECK ]] ; then
    printf "Invalid auto save number given: %s\\n" "${AUTOSAVENUM}"
    AUTOSAVENUM="3"
fi
printf "Setting auto save number to %s\\n" "${AUTOSAVENUM}"
setiniprop "Engine.ini" "\/Script\/FactoryGame\.FGSaveSession" "mNumRotatingAutosaves" "${AUTOSAVENUM}"
[[ "${CRASHREPORT,,}" == "true" ]] && CRASHREPORT="true" || CRASHREPORT="false"
printf "Setting crash reporting to %s\\n" "${CRASHREPORT^}"
setiniprop "Engine.ini" "CrashReportClient" "bImplicitSend" "${CRASHREPORT^}"

## ServerSettings.ini
[[ "${AUTOPAUSE,,}" == "true" ]] && AUTOPAUSE="true" || AUTOPAUSE="false"
printf "Setting auto pause to %s\\n" "${AUTOPAUSE^}"
setiniprop "ServerSettings.ini" "\/Script\/FactoryGame\.FGServerSubsystem" "mAutoPause" "${AUTOPAUSE^}"
[[ "${AUTOSAVEONDISCO,,}" == "true" ]] && AUTOSAVEONDISCO="true" || AUTOSAVEONDISCO="false"
printf "Setting auto save on disconnect to %s\\n" "${AUTOSAVEONDISCO^}"
setiniprop "ServerSettings.ini" "\/Script\/FactoryGame\.FGServerSubsystem" "mAutoSaveOnDisconnect" "${AUTOSAVEONDISCO^}"

## GameUserSettings.ini
if ! [[ "$AUTOSAVEINTERVAL" =~ $NUMCHECK ]] ; then
    printf "Invalid auto save interval given: %s\\n" "${AUTOSAVEINTERVAL}"
    AUTOSAVEINTERVAL="300"
fi
printf "Setting auto save interval to %ss\\n" "${AUTOSAVEINTERVAL}"
setinival "GameUserSettings.ini" "\/Script\/FactoryGame\.FGGameUserSettings" "FG.AutosaveInterval" "${AUTOSAVEINTERVAL}"

if ! [[ "${SKIPUPDATE,,}" == "true" ]]; then
    if [[ "${STEAMBETA,,}" == "true" ]]; then
        printf "Experimental flag is set. Experimental will be downloaded instead of Early Access.\\n"
        STEAMBETAFLAG=" -beta experimental validate"
    fi

    space=$(stat -f --format="%a*%S" .)
    space=$((space/1024/1024/1024))
    printf "Checking available space...%sGB detected\\n" "${space}"

    if [[ "$space" -lt 5 ]]; then
        printf "You have less than 5GB (%sGB detected) of available space to download the game.\\nIf this is a fresh install, it will probably fail.\\n" "${space}"
    fi

    printf "Downloading the latest version of the game...\\n"
    
    /home/steam/steamcmd/steamcmd.sh +login anonymous +force_install_dir /config/gamefiles +app_update "$STEAMAPPID" $STEAMBETAFLAG +quit
else
    printf "Skipping update as flag is set\\n"
fi

cp -a "/config/saves/." "/config/backups/"
cp -a "${GAMESAVESDIR}/server/." "/config/backups" # useless in first run, but useful in additional runs
rm -rf "${GAMESAVESDIR}/server"
ln -sf "/config/saves" "${GAMESAVESDIR}/server"
ln -sf "/config/ServerSettings.${SERVERQUERYPORT}" "${GAMESAVESDIR}/ServerSettings.${SERVERQUERYPORT}"

cp /home/steam/*.ini "${GAMECONFIGDIR}/Config/LinuxServer"

if [ ! -f "/config/gamefiles/Engine/Binaries/Linux/UE4Server-Linux-Shipping" ]; then
    printf "Game binary is missing.\\n"
    exit 1
fi

cd /config/gamefiles || exit 1

Engine/Binaries/Linux/UE4Server-Linux-Shipping FactoryGame -log -NoSteamClient -unattended ?listen -Port="$SERVERGAMEPORT" -BeaconPort="$SERVERBEACONPORT" -ServerQueryPort="$SERVERQUERYPORT" -multihome="$SERVERIP"
