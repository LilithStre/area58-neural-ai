#!/usr/bin/env bash
# ============================================================
# Area58 Neural AI — FASE 1: Setup progetto + build ISO stock
# Uso:  bash fase1.sh
# Prerequisito consigliato: sudo pacman -Syu (evita upgrade parziali)
# ============================================================
set -euo pipefail

# Il progetto è la cartella in cui si trova lo script
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

if [ "$EUID" -eq 0 ]; then
    echo "Non eseguire come root: lo script usa sudo dove serve." >&2
    exit 1
fi
command -v pacman >/dev/null || { echo "Serve un host Arch Linux." >&2; exit 1; }

echo "=========================================="
echo " Area58 Neural AI — Fase 1"
echo "=========================================="

# --- 1. Struttura progetto ---
if [ -d .git ]; then
    echo ">> Repo git già esistente, skip"
else
    git init -b main
    echo ">> Repo git inizializzato (branch main)"
fi
mkdir -p profile docs calamares .github/workflows

# --- 2. Dipendenze ---
echo ">> Verifica/installazione dipendenze..."
sudo pacman -S --needed --noconfirm archiso git qemu-desktop edk2-ovmf

# --- 3. Profilo releng stock (copiato solo se assente) ---
# NB: releng non contiene build.sh; il marker giusto è profiledef.sh
if [ -f profile/profiledef.sh ]; then
    echo ">> Profilo archiso già presente, skip copia (personalizzazioni al sicuro)"
else
    cp -r /usr/share/archiso/configs/releng/. profile/
    echo ">> Profilo releng stock copiato in profile/"
fi

# --- 4. .gitignore (solo se assente) ---
if [ ! -f .gitignore ]; then
    cat > .gitignore <<'EOF'
out/
work/
*.iso
*.img
roadmap.pdf
__pycache__/
EOF
    echo ">> .gitignore creato"
fi

# --- 5. Config git minima (solo se manca) ---
if ! git config user.email > /dev/null 2>&1; then
    echo ">> Configuro identità git locale per questo repo"
    git config user.name  "Area58"
    git config user.email "area58@localhost"
fi

# --- 6. Build ISO stock ---
echo ""
echo ">> BUILD AVVIATA — può richiedere 10-30 minuti, non interrompere"
echo ""
sudo rm -rf work            # build pulita: niente residui di run precedenti
mkdir -p out
sudo mkarchiso -v -w work -o out/ profile/

# --- 7. Permessi e checksum ---
sudo chown -R "$USER":"$(id -gn)" out
( cd out && sha256sum -- *.iso > SHA256SUMS )
echo ">> SHA256SUMS generato (verifica: cd out && sha256sum -c SHA256SUMS)"

# --- 8. Commit iniziale ---
git add .
git commit -m "init: Area58 Neural AI — profilo archiso stock + struttura progetto" \
    || echo ">> Nessuna modifica da committare"

# --- 9. Riepilogo ---
ISO="$(ls -t out/*.iso | head -n1)"
echo ""
echo "=========================================="
echo " BUILD COMPLETATA ✓"
echo "=========================================="
ls -lh out/
echo ""
echo "La ISO stock si chiama archlinux-<data>-x86_64.iso — è NORMALE,"
echo "il nome cambia solo dopo il branding (Fase 8)."

# --- 10. Test QEMU (opzionale, UEFI se OVMF disponibile) ---
OVMF="/usr/share/edk2/x64/OVMF_CODE.4m.fd"
QEMU_CMD=(qemu-system-x86_64 -enable-kvm -cpu host -m 4096 -smp 4 -cdrom "$ISO")
if [ -f "$OVMF" ]; then
    QEMU_CMD+=(-drive "if=pflash,format=raw,readonly=on,file=$OVMF")
else
    echo ">> OVMF non trovato: il test partirà in BIOS, non UEFI"
fi

read -rp "Avviare il test QEMU adesso? [s/N]: " risposta
if [[ "$risposta" =~ ^[sS]$ ]]; then
    "${QEMU_CMD[@]}"
else
    echo ""
    echo "Per testare dopo:"
    echo "  cd $PROJECT_DIR"
    echo "  ${QEMU_CMD[*]}"
fi

echo ""
echo ">> Fase 1 completata. Nel live: prompt root@archiso (senza desktop) = corretto."
