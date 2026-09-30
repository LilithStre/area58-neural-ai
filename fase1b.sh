#!/bin/bash
set -e

# ============================================================
# Area58 Neural AI — FASE 1B: Commit + SSH + Push su GitHub
# Uso: bash fase1b.sh        (funziona su qualsiasi Linux)
# ============================================================

REPO_DIR="$HOME/progetti/area58-neural-ai"
REMOTE="git@github.com:LilithStre/area58-neural-ai.git"

cd "$REPO_DIR"

echo "=========================================="
echo " Area58 Neural AI — Fase 1B: push GitHub"
echo "=========================================="

# --- 1. Identita git (globale, solo se manca) ---
if ! git config --global user.email > /dev/null 2>&1; then
    git config --global user.name "LilithStre"
    git config --global user.email "lilith@area58.it"
fi
echo ">> Identita git: $(git config --global user.name) <$(git config --global user.email)>"

# --- 2. Ramo di default 'main' ---
git config --global init.defaultBranch main
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
if [ "$BRANCH" = "master" ]; then
    git branch -m main
    echo ">> Ramo rinominato: master -> main"
fi

# --- 3. Commit (se c'e' qualcosa da committare) ---
git add README.md fase1.sh fase1b.sh
if ! git diff --cached --quiet; then
    git commit -m "init: Area58 Neural AI — struttura progetto + script Fase 1"
    echo ">> Commit creato"
else
    echo ">> Nessuna modifica nuova da committare"
fi

# --- 4. Chiave SSH (solo se manca) ---
mkdir -p ~/.ssh && chmod 700 ~/.ssh
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo ">> Genero chiave SSH (senza passphrase)..."
    ssh-keygen -t ed25519 -C "area58" -f ~/.ssh/id_ed25519 -N ""
else
    echo ">> Chiave SSH gia' presente"
fi

# --- 5. Mostra la chiave pubblica e pausa per GitHub ---
echo ""
echo "=========================================="
echo " COPIA QUESTA RIGA:"
echo "=========================================="
cat ~/.ssh/id_ed25519.pub
echo "=========================================="
echo " Poi su GitHub:"
echo "  avatar (in alto a destra) -> Settings"
echo "  -> SSH and GPG keys -> New SSH key"
echo "  -> incolla -> Add SSH key"
echo "=========================================="
read -rp "Hai aggiunto la chiave su GitHub? [s/N]: " ok
if ! [[ "$ok" =~ ^[sS]$ ]]; then
    echo ""
    echo "Aggiungi la chiave sul sito, poi rilancia:  bash fase1b.sh"
    exit 0
fi

# --- 6. Test connessione ---
echo ">> Test connessione GitHub..."
if ssh -T -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo ">> Autenticazione GitHub OK"
else
    echo "!! Autenticazione NON riuscita — verifica la chiave su GitHub e rilancia"
    exit 1
fi

# --- 7. Remote + push ---
if git remote get-url origin > /dev/null 2>&1; then
    git remote set-url origin "$REMOTE"
else
    git remote add origin "$REMOTE"
fi

git push -u origin main

echo ""
echo "=========================================="
echo " PUSH COMPLETATO ✓"
echo "=========================================="
echo "Verifica nel browser:"
echo "  https://github.com/LilithStre/area58-neural-ai"
