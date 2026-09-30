#!/usr/bin/env bash
# Area58 Neural AI — build dell'ISO da Linux Mint usando un container Arch.
# Uso:   bash build-docker.sh          # solo build
#        bash build-docker.sh test     # build + avvio in QEMU
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

command -v docker >/dev/null || {
    echo "Docker non trovato. Installa con: sudo apt install docker.io" >&2
    exit 1
}

# Usa sudo solo se l'utente non è nel gruppo docker
DOCKER=docker
docker info >/dev/null 2>&1 || DOCKER="sudo docker"

mkdir -p profile out

echo ">> BUILD AVVIATA (prima volta: scarica l'immagine Arch, poi 15-40 min)"
$DOCKER run --rm --privileged \
    -v "$PWD":/build -w /build \
    archlinux:latest bash -euc '
        pacman -Syu --noconfirm archiso
        if [ ! -f profile/profiledef.sh ]; then
            echo ">> Copio il profilo releng stock in profile/"
            cp -r /usr/share/archiso/configs/releng/. profile/
        fi
        rm -rf /tmp/work
        mkarchiso -v -w /tmp/work -o /build/out /build/profile
    '

# I file creati nel container appartengono a root: restituiscili a te
sudo chown -R "$USER":"$(id -gn)" out profile

( cd out && sha256sum -- *.iso > SHA256SUMS )
echo ""
echo ">> BUILD COMPLETATA"
ls -lh out/

if [ "${1:-}" = "test" ]; then
    ISO="$(ls -t out/*.iso | head -n1)"
    CMD=(qemu-system-x86_64 -enable-kvm -cpu host -m 4096 -smp 4 -cdrom "$ISO")
    for f in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd; do
        if [ -f "$f" ]; then
            CMD+=(-drive "if=pflash,format=raw,readonly=on,file=$f")
            echo ">> Avvio in UEFI ($f)"
            break
        fi
    done
    "${CMD[@]}"
fi
