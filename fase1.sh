#!/bin/bash
set -e

# ============================================================
# Area58 Neural AI — FASE 1: Setup progetto + Build ISO stock
# Uso:  bash fase1.sh
# ============================================================

PROJECT_DIR="$HOME/progetti/area58-neural-ai"

echo "=========================================="
echo " Area58 Neural AI — Fase 1"
echo "=========================================="

# --- 1. Struttura progetto ---
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

if [ -d .git ]; then
    echo ">> Repo git già esistente, skip"
else
    git init
    echo ">> Repo git inizializzato"
fi

mkdir -p profile docs calamares .github/workflows

# --- 2. Dipendenze ---
echo ">> Verifica/installazione dipendenze..."
sudo pacman -S --needed --noconfirm archiso git qemu-desktop

# --- 3. Profilo releng stock (copiato solo se assente) ---
if [ -f profile/build.sh ]; then
    echo ">> Profilo archiso già presente, skip copia"
else
    cp -r /usr/share/archiso/configs/releng/. profile/
    echo ">> Profilo releng stock copiato in profile/"
fi

# --- 4. .gitignore ---
cat > .gitignore <<'EOF'
out/
work/
*.iso
*.img
roadmap.pdf
__pycache__/
EOF

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
sudo ./profile/build.sh -v -w work -o out/

# --- 7. Checksum ---
cd "$PROJECT_DIR"
sha256sum out/*.iso > out/SHA256SUMS
echo ">> SHA256SUMS generato"

# --- 8. Commit iniziale ---
git add .
git commit -m "init: Area58 Neural AI — profilo archiso stock + struttura progetto" \
    || echo ">> Nessuna modifica da committare"

# --- 9. Riepilogo ---
echo ""
echo "=========================================="
echo " BUILD COMPLETATA ✓"
echo "=========================================="
ls -lh out/
echo ""
echo "La ISO stock si chiama archlinux-x86_64 — è NORMALE,"
echo "il nome cambia solo dopo il branding (Fase 8)."

# --- 10. Test QEMU (opzionale) ---
read -rp "Avviare il test QEMU adesso? [s/N]: " risposta
if [[ "$risposta" =~ ^[sS]$ ]]; then
    qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cdrom out/*.iso
else
    echo ""
    echo "Per testare dopo:"
    echo "  cd $PROJECT_DIR"
    echo "  qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cdrom out/*.iso"
fi

echo ""
echo ">> Fase 1 completata. Nel live: prompt root@archiso (senza desktop) = corretto."
