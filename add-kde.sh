#!/usr/bin/env bash
# ============================================================
# Area58 Neural AI — Fase 2-3: aggiunge KDE Plasma al profilo archiso
#   - pacchetti KDE minimali
#   - utente live "liveuser" con login automatico (SDDM)
#   - avvio grafico + sfondo Area58 al primo login
# Uso (dalla radice del repo):  bash add-kde.sh
# È ripetibile: non duplica pacchetti né file.
# ============================================================
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

P=profile
A="$P/airootfs"
[ -f "$P/packages.x86_64" ] || { echo "profile/packages.x86_64 non trovato: lancia prima build-docker.sh" >&2; exit 1; }

# --- 1. Pacchetti KDE minimali ---
PKGS=(plasma-desktop sddm konsole dolphin kate kscreen powerdevil
      xdg-desktop-portal-kde breeze-gtk kde-gtk-config noto-fonts xorg-server)
[ -z "$(tail -c1 "$P/packages.x86_64")" ] || echo >> "$P/packages.x86_64"
for p in "${PKGS[@]}"; do
    grep -qx "$p" "$P/packages.x86_64" || echo "$p" >> "$P/packages.x86_64"
done
echo ">> Pacchetti KDE aggiunti a packages.x86_64"

# --- 2. SDDM: login automatico dell'utente live in Plasma (Wayland) ---
mkdir -p "$A/etc/sddm.conf.d"
cat > "$A/etc/sddm.conf.d/10-area58-autologin.conf" <<'EOF'
[Autologin]
User=liveuser
Session=plasma
Relogin=false
EOF

# --- 3. Creazione dell'utente live all'avvio ---
mkdir -p "$A/usr/local/bin" "$A/etc/systemd/system/multi-user.target.wants"
cat > "$A/usr/local/bin/area58-live-setup.sh" <<'EOF'
#!/usr/bin/bash
# Crea l'utente live senza password (solo gruppi esistenti)
set -e
id liveuser >/dev/null 2>&1 && exit 0
G=$(for g in wheel audio video storage; do getent group "$g" >/dev/null && echo "$g"; done | paste -sd,)
useradd -m ${G:+-G "$G"} -s /bin/bash liveuser
passwd -d liveuser
EOF
cat > "$A/etc/systemd/system/area58-live-setup.service" <<'EOF'
[Unit]
Description=Area58 - crea l'utente live
Before=sddm.service display-manager.service
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/bin/bash /usr/local/bin/area58-live-setup.sh

[Install]
WantedBy=multi-user.target
EOF
ln -sf /etc/systemd/system/area58-live-setup.service \
       "$A/etc/systemd/system/multi-user.target.wants/area58-live-setup.service"

# --- 4. Avvio grafico con SDDM ---
ln -sf /usr/lib/systemd/system/sddm.service "$A/etc/systemd/system/display-manager.service"
ln -sf /usr/lib/systemd/system/graphical.target "$A/etc/systemd/system/default.target"

# --- 5. Sfondo Area58 al primo login (una sola volta) ---
mkdir -p "$A/etc/skel/.config/autostart"
cat > "$A/usr/local/bin/area58-wallpaper.sh" <<'EOF'
#!/usr/bin/bash
M="$HOME/.config/.area58-wallpaper-done"
[ -e "$M" ] && exit 0
sleep 6
plasma-apply-wallpaperimage /usr/share/wallpapers/Area58/contents/images/1920x1080.jpg && touch "$M"
EOF
cat > "$A/etc/skel/.config/autostart/area58-wallpaper.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Area58 wallpaper
Exec=/usr/bin/bash /usr/local/bin/area58-wallpaper.sh
EOF

# --- 6. Test in VM: più RAM e scheda video virtio (se non già fatto) ---
if [ -f build-docker.sh ] && ! grep -q -- '-vga virtio' build-docker.sh; then
    sed -i 's/-m 4096/-m 6144/; s/-cdrom "\$ISO")/-cdrom "$ISO" -vga virtio)/' build-docker.sh
    echo ">> build-docker.sh: VM con 6 GB di RAM e -vga virtio"
fi

echo ""
echo ">> Fatto. Ora ricompila e prova:  bash build-docker.sh test"
