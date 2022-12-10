#!/bin/bash

set -e

if [[ "$DEBUG" == "true" ]]; then
    printf "Debugging enabled (the container will exit after printing the debug info)\\n\\nPrinting environment variables:\\n"
    export

    echo "
System info:
OS:  $(uname -a)
CPU: $(lscpu | grep 'Model name:' | sed 's/Model name:[[:space:]]*//g')
RAM: $(awk '/MemAvailable/ {printf( "%d\n", $2 / 1024000 )}' /proc/meminfo)GB/$(awk '/MemTotal/ {printf( "%d\n", $2 / 1024000 )}' /proc/meminfo)GB
HDD: $(df -h | awk '$NF=="/"{printf "%dGB/%dGB (%s used)\n", $3,$2,$5}')"
    printf "\\nCurrent user:\\n%s" "$(id)"
    printf "\\nProposed user:\\nuid=%s(?) gid=%s(?) groups=%s(?)\\n" "$PUID" "$PGID" "$PGID"
    printf "\\nExiting...\\n"
    exit 1
fi

CURRENTUID=$(id -u)
if [[ "$CURRENTUID" -ne "0" ]]; then
    printf "Current user is not root (%s)\\nPass your user and group to the container using the PGID and PUID environment variables\\nDo not use the --user flag (or user: field in Docker Compose)\\n" "$CURRENTUID"
    exit 1
fi

ramAvailable=$(awk '/MemAvailable/ {printf( "%d\n", $2 / 1024000 )}' /proc/meminfo)
printf "Checking available memory...%sGB detected\\n" "$ramAvailable"

if [[ "$ramAvailable" -lt 12 ]]; then
    printf "You have less than the required 12GB minmum (%sGB detected) of available RAM to run the game server.\\nIt is likely that the server will fail to load properly.\\n" "$ramAvailable"
fi

mkdir -p \
    /config/backups \
    /config/gamefiles \
    /config/saved/blueprints \
    /config/saved/server \
    "${GAMECONFIGDIR}/Config/LinuxServer" \
    "${GAMECONFIGDIR}/Logs" \
    "${GAMESAVESDIR}/server" \
    || exit 1

NUMCHECK='^[0-9]+$'

# check if the user and group IDs have been set
if ! [[ "$PGID" =~ $NUMCHECK ]] ; then
    printf "Invalid group id given: %s\\n" "$PGID"
    PGID="1000"
elif [[ "$PGID" -eq 0 ]]; then
    printf "PGID/group cannot be 0 (root)\\n"
    exit 1
fi

if ! [[ "$PUID" =~ $NUMCHECK ]] ; then
    printf "Invalid user id given: %s\\n" "$PUID"
    PUID="1000"
elif [[ "$PUID" -eq 0 ]]; then
    printf "PUID/user cannot be 0 (root)\\n"
    exit 1
fi

groupmod -g "$PGID" steam
usermod -u "$PUID" steam
chown -R "$PUID":"$PGID" /config /home/steam
exec gosu steam "/home/steam/run.sh" "$@"
