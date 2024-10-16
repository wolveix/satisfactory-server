#!/bin/bash

set -e

printf "===== Satisfactory Server %s =====\\nhttps://github.com/wolveix/satisfactory-server\\n\\n" "$VERSION"

CURRENTUID=$(id -u)
HOME="/home/steam"
MSGERROR="\033[0;31mERROR:\033[0m"
MSGWARNING="\033[0;33mWARNING:\033[0m"
NUMCHECK='^[0-9]+$'
RAMAVAILABLE=$(awk '/MemAvailable/ {printf( "%d\n", $2 / 1024000 )}' /proc/meminfo)
USER="steam"

if [[ "${DEBUG,,}" == "true" ]]; then
    printf "Debugging enabled (the container will exit after printing the debug info)\\n\\nPrinting environment variables:\\n"
    export

    echo "
System info:
OS:  $(uname -a)
CPU: $(lscpu | grep '^Model name:' | sed 's/Model name:[[:space:]]*//g')
RAM: $(awk '/MemAvailable/ {printf( "%d\n", $2 / 1024000 )}' /proc/meminfo)GB/$(awk '/MemTotal/ {printf( "%d\n", $2 / 1024000 )}' /proc/meminfo)GB
HDD: $(df -h | awk '$NF=="/"{printf "%dGB/%dGB (%s used)\n", $3,$2,$5}')"
    printf "\\nCurrent version:\\n%s" "${VERSION}"
    printf "\\nCurrent user:\\n%s" "$(id)"
    printf "\\nProposed user:\\nuid=%s(?) gid=%s(?) groups=%s(?)\\n" "$PUID" "$PGID" "$PGID"
    printf "\\nExiting...\\n"
    exit 1
fi

# check that the cpu isn't generic, as Satisfactory will normally crash
if [[ "$VMOVERRIDE" == "true" ]]; then
    printf "${MSGWARNING} VMOVERRIDE is enabled, skipping CPU model check. Satisfactory might crash!\\n"
else
    cpu_model=$(lscpu | grep 'Model name:' | sed 's/Model name:[[:space:]]*//g')
    if [[ "$cpu_model" == "Common KVM processor" || "$cpu_model" == *"QEMU"* ]]; then
        printf "${MSGERROR} Your CPU model is configured as \"${cpu_model}\", which will cause Satisfactory to crash.\\nIf you have control over your hypervisor (ESXi, Proxmox, etc.), you should be able to easily change this.\\nOtherwise contact your host/administrator for assistance.\\n"
        exit 1
    fi
fi

printf "Checking available memory: %sGB detected\\n" "$RAMAVAILABLE"
if [[ "$RAMAVAILABLE" -lt 8 ]]; then
    printf "${MSGWARNING} You have less than the required 8GB minimum (%sGB detected) of available RAM to run the game server.\\nThe server will likely run fine, though may run into issues in the late game (or with 4+ players).\\n" "$RAMAVAILABLE"
fi

# prevent large logs from accumulating by default
if [[ "${LOG,,}" != "true" ]]; then
    printf "Clearing old Satisfactory logs (set LOG=true to disable this)\\n"
    if [ -d "/config/gamefiles/FactoryGame/Saved/Logs" ] && [ -n "$(find /config/gamefiles/FactoryGame/Saved/Logs -type f -print -quit)" ]; then
        rm -r /config/gamefiles/FactoryGame/Saved/Logs/*
    fi
fi

# check if the user and group IDs have been set
if [[ "$CURRENTUID" -ne "0" ]] && [[ "${ROOTLESS,,}" != "true" ]]; then
    printf "${MSGERROR} Current user (%s) is not root (0)\\nPass your user and group to the container using the PGID and PUID environment variables\\nDo not use the --user flag (or user: field in Docker Compose) without setting ROOTLESS=true\\n" "$CURRENTUID"
    exit 1
fi

if ! [[ "$PGID" =~ $NUMCHECK ]] ; then
    printf "${MSGWARNING} Invalid group id given: %s\\n" "$PGID"
    PGID="1000"
elif [[ "$PGID" -eq 0 ]]; then
    printf "${MSGERROR} PGID/group cannot be 0 (root)\\n"
    exit 1
fi

if ! [[ "$PUID" =~ $NUMCHECK ]] ; then
    printf "${MSGWARNING} Invalid user id given: %s\\n" "$PUID"
    PUID="1000"
elif [[ "$PUID" -eq 0 ]]; then
    printf "${MSGERROR} PUID/user cannot be 0 (root)\\n"
    exit 1
fi

if [[ "${ROOTLESS,,}" != "true" ]]; then
  if [[ $(getent group $PGID | cut -d: -f1) ]]; then
      usermod -a -G "$PGID" steam
  else
      groupmod -g "$PGID" steam
  fi

  if [[ $(getent passwd ${PUID} | cut -d: -f1) ]]; then
      USER=$(getent passwd $PUID | cut -d: -f1)
  else
      usermod -u "$PUID" steam
  fi
fi

if [[ ! -w "/config" ]]; then
    echo "The current user does not have write permissions for /config"
    exit 1
fi

mkdir -p \
    /config/backups \
    /config/gamefiles \
    /config/logs/steam \
    /config/saved/blueprints \
    /config/saved/server \
    "${GAMECONFIGDIR}/Config/LinuxServer" \
    "${GAMECONFIGDIR}/Logs" \
    "${GAMESAVESDIR}/server" \
    /home/steam/.steam/root \
    /home/steam/.steam/steam \
    || exit 1

echo "Satisfactory logs can be found in /config/gamefiles/FactoryGame/Saved/Logs" > /config/logs/satisfactory-path.txt

if [[ "${ROOTLESS,,}" != "true" ]]; then
  chown -R "$PUID":"$PGID" /config /home/steam /tmp/dumps
  exec gosu "$USER" "/home/steam/run.sh" "$@"
else
  exec "/home/steam/run.sh" "$@"
fi
