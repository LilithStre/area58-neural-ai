#!/usr/bin/env bash
# Area58 Neural AI — imposta l'icona del menu Area58 al primo login del desktop.
# Riscrive lo script di primo avvio nel profilo (sfondo + icona del menu).
# Uso (dalla radice del repo):  bash patch-menu-icon.sh
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

F=profile/airootfs/usr/local/bin/area58-wallpaper.sh
[ -d "$(dirname "$F")" ] || { echo "Lancia prima add-kde.sh" >&2; exit 1; }

cat > "$F" <<'EOF'
#!/usr/bin/bash
# Primo login: applica sfondo Area58 e icona del menu (una sola volta)
M="$HOME/.config/.area58-wallpaper-done"
[ -e "$M" ] && exit 0
sleep 6
plasma-apply-wallpaperimage /usr/share/wallpapers/Area58/contents/images/1920x1080.jpg || true
# Cambia l'icona del pulsante del menu (launcher) tramite lo scripting di Plasma
dbus-send --session --dest=org.kde.plasmashell --type=method_call /PlasmaShell \
    org.kde.PlasmaShell.evaluateScript \
    string:'var ps = panels(); for (var i = 0; i < ps.length; i++) { var ws = ps[i].widgets(); for (var j = 0; j < ws.length; j++) { if (ws[j].type == "org.kde.plasma.kickoff") { ws[j].currentConfigGroup = ["General"]; ws[j].writeConfig("icon", "area58-menu"); } } }' || true
touch "$M"
EOF
echo ">> Script di primo avvio aggiornato: $F"
echo ">> Ora ricompila e prova:  bash build-docker.sh test"
