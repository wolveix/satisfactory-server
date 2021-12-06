#!/bin/bash

set -e

set_ini_prop() {
    sed "/\[$2\]/,/^\[/ s/$3\=.*/$3=$4/" -i "/home/steam/$1"
}

set_ini_val() {
    sed "/\[$2\]/,/^\[/ s/((\"$3\",.*))/((\"$3\", $4))/" -i "/home/steam/$1"
}

NUMCHECK='^[0-9]+$'

# Engine.ini
if ! [[ "$AUTOSAVENUM" =~ $NUMCHECK ]] ; then
    printf "Invalid autosave number given: %s\\n" "${AUTOSAVENUM}"
    AUTOSAVENUM="3"
fi
printf "Setting autosave number to %s\\n" "${AUTOSAVENUM}"
set_ini_prop "Engine.ini" "\/Script\/FactoryGame\.FGSaveSession" "mNumRotatingAutosaves" "${AUTOSAVENUM}"
[[ "${CRASHREPORT,,}" == "true" ]] && CRASHREPORT="true" || CRASHREPORT="false"
printf "Setting crash reporting to %s\\n" "${CRASHREPORT^}"
set_ini_prop "Engine.ini" "CrashReportClient" "bImplicitSend" "${CRASHREPORT^}"

## Game.ini
if ! [[ "$MAXPLAYERS" =~ $NUMCHECK ]] ; then
    printf "Invalid max players given: %s\\n" "${MAXPLAYERS}"
    MAXPLAYERS="4"
fi
printf "Setting max players to %s\\n" "${MAXPLAYERS}"
set_ini_prop "Game.ini" "\/Script\/Engine\.GameSession" "MaxPlayers" "${MAXPLAYERS}"

# GameUserSettings.ini
if ! [[ "$AUTOSAVEINTERVAL" =~ $NUMCHECK ]] ; then
    printf "Invalid autosave interval given: %s\\n" "${AUTOSAVEINTERVAL}"
    AUTOSAVEINTERVAL="300"
fi
printf "Setting autosave interval to %ss\\n" "${AUTOSAVEINTERVAL}"
set_ini_val "GameUserSettings.ini" "\/Script\/FactoryGame\.FGGameUserSettings" "FG.AutosaveInterval" "${AUTOSAVEINTERVAL}"

[[ "${DISABLESEASONALEVENTS,,}" == "true" ]] && DISABLESEASONALEVENTS="1" || DISABLESEASONALEVENTS="0"
printf "Setting disable seasonal events to %s\\n" "${DISABLESEASONALEVENTS}"
set_ini_val "GameUserSettings.ini" "\/Script\/FactoryGame\.FGGameUserSettings" "FG.DisableSeasonalEvents" "${DISABLESEASONALEVENTS}"

# ServerSettings.ini
[[ "${AUTOPAUSE,,}" == "true" ]] && AUTOPAUSE="true" || AUTOPAUSE="false"
printf "Setting auto pause to %s\\n" "${AUTOPAUSE^}"
set_ini_prop "ServerSettings.ini" "\/Script\/FactoryGame\.FGServerSubsystem" "mAutoPause" "${AUTOPAUSE^}"

[[ "${AUTOSAVEONDISCONNECT,,}" == "true" ]] && AUTOSAVEONDISCONNECT="true" || AUTOSAVEONDISCONNECT="false"
printf "Setting autosave on disconnect to %s\\n" "${AUTOSAVEONDISCONNECT^}"
set_ini_prop "ServerSettings.ini" "\/Script\/FactoryGame\.FGServerSubsystem" "mAutoSaveOnDisconnect" "${AUTOSAVEONDISCONNECT^}"

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
    
    /home/steam/steamcmd/steamcmd.sh +force_install_dir /config/gamefiles +login anonymous +app_update "$STEAMAPPID" $STEAMBETAFLAG +quit
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

exec ./Engine/Binaries/Linux/UE4Server-Linux-Shipping FactoryGame -log -NoSteamClient -unattended ?listen -Port="$SERVERGAMEPORT" -BeaconPort="$SERVERBEACONPORT" -ServerQueryPort="$SERVERQUERYPORT" -multihome="$SERVERIP" "$@"
