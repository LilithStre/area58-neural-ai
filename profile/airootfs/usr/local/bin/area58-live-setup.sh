#!/usr/bin/bash
# Crea l'utente live senza password (solo gruppi esistenti)
set -e
id liveuser >/dev/null 2>&1 && exit 0
G=$(for g in wheel audio video storage; do getent group "$g" >/dev/null && echo "$g"; done | paste -sd,)
useradd -m ${G:+-G "$G"} -s /bin/bash liveuser
passwd -d liveuser
