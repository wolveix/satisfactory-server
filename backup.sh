#!/bin/bash
TIME=$(date +%d-%B-%Y_%H-%M)
FILENAME="backup-${TIME}.tar.gz"
SRCDIR=/config/savefiles
DESDIR=/config/savefilebackups
printf "Creating new backup: $FILENAME\\n"
tar -cpzf "${DESDIR}/${FILENAME}" "$SRCDIR"

if [[ ! "$MAXBACKUPS" -gt 0 ]]; then
  exit 0
fi

CURRENTBACKUPS="$(ls $DESDIR | wc -l)"
if [[ "$CURRENTBACKUPS" -gt "$MAXBACKUPS" ]]; then
  OLDESTBACKUP="$(ls -t $DESDIR | tail -1)"
  printf "Removing oldest backup: $OLDESTBACKUP\\n"
  rm "${DESDIR}/${OLDESTBACKUP}"
fi