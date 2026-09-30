#!/usr/bin/env bash
# Copia sfondo e icone dentro il profilo archiso del progetto.
# Uso: bash area58-branding/install-branding.sh   (dalla radice del repo)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
DEST="../profile"
[ -f "$DEST/profiledef.sh" ] || { echo "profile/ non trovato: lancia prima la build." >&2; exit 1; }
mkdir -p "$DEST/airootfs"
cp -r airootfs/. "$DEST/airootfs/"
echo ">> Sfondo e icone copiati in profile/airootfs"
