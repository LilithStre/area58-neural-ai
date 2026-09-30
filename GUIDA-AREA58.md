# Area58 Neural AI — Guida Completa al Progetto

**Distro Linux live/installabile: Pro Audio + KDE Plasma + AI Locale**
*Autore: Lilith — v1.0*

---

## 0. Panoramica

Area58 Neural AI è una distribuzione Linux basata su **Arch Linux (archiso)**
che offre:

- Stack pro-audio completo (PipeWire + DAW + plugin)
- Desktop KDE Plasma con dock stile macOS (Plank, sessione X11)
- AI locale: Ollama (backend) + Open WebUI / WebLLM (browser)
- Installer grafico (Calamares)

**Hardware di riferimento (banco di prova):** ACEMAGIC M1, Ryzen 7 7735HS,
Radeon 680M iGPU, 16 GB RAM. La distro NON è vincolata a questo hardware.

---

## 1. Prerequisiti

- Macchina host con **Arch Linux** (obbligatorio: `mkarchiso` esiste solo
  su Arch — su Debian/Ubuntu/Mint la build NON parte)
- `archiso`, `git`, QEMU per i test
- ~20 GB di spazio libero per build

```bash
sudo pacman -S archiso git qemu-desktop
```

---

## 2. Struttura del progetto

```bash
mkdir -p ~/progetti/area58-neural-ai
cd ~/progetti/area58-neural-ai

mkdir -p profile docs \
         airootfs/etc/security/limits.d \
         airootfs/etc/sysctl.d \
         airootfs/etc/skel/.config/autostart \
         airootfs/usr/local/bin \
         calamares .github/workflows
```

Albero completo:

```
area58-neural-ai/
├── GUIDA-AREA58.md          # questo file
├── docs/roadmap.md          # roadmap versionata
├── .gitignore
├── profile/                 # profilo archiso (da releng)
│   ├── packages.x86_64
│   ├── pacman.conf
│   ├── profiledef.sh
│   ├── build.sh
│   └── grub/grub.cfg
├── airootfs/                # overlay rootfs
│   └── etc/, usr/local/bin/
├── calamares/
└── .github/workflows/build.yml
```

---

## 3. Setup iniziale (git + profilo archiso)

```bash
git init

cat > .gitignore <<'EOF'
out/
work/
*.iso
*.img
roadmap.pdf
__pycache__/
EOF

# copia il profilo releng come base
sudo pacman -S archiso
cp -r /usr/share/archiso/configs/releng/. profile/
```

**Prima build di prova PRIMA di personalizzare** (mai modificare una
ricetta che non hai ancora visto cucinare):

```bash
sudo ./profile/build.sh -v -w work -o out/
qemu-system-x86_64 -enable-kvm -m 4096 -cdrom out/*.iso
```

Nota: la workdir va su disco (`work/`), non su `/tmp` (che è tmpfs: con
poca RAM rischia `No space left on device`).

Primo commit:

```bash
git add .
git commit -m "init: Area58 Neural AI — profilo archiso base + struttura progetto"
```

---

## 4. Branding

### 4.1 profile/profiledef.sh

```bash
iso_name="area58-neural-ai"
iso_label="AREA58_AI_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Area58 Neural AI Project"
iso_application="Area58 Neural AI — Pro Audio / KDE / Local AI Live Installer"
```

### 4.2 airootfs/etc/os-release

```ini
NAME="Area58 Neural AI"
PRETTY_NAME="Area58 Neural AI"
ID=area58
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;255;145;40"
HOME_URL="https://area58.it"
DOCUMENTATION_URL="https://area58.it/docs"
SUPPORT_URL="https://area58.it/support"
BUG_REPORT_URL="https://github.com/LilithStre/area58-neural-ai/issues"
```

### 4.3 Hostname

**IMPORTANTE:** l'hostname statico deve essere RFC 1123 — solo lettere,
cifre e trattini, tutto minuscolo. Niente underscore (`area58_Neural_ai`
NON è valido e systemd-hostnamed lo rifiuta).

`airootfs/etc/hostname`:
```
area58-neural-ai
```

`airootfs/etc/machine-info` (qui si può scrivere liberamente):
```ini
PRETTY_HOSTNAME="Area58 Neural AI"
```

Comando equivalente a mano sul sistema installato:
```bash
sudo hostnamectl set-hostname area58-neural-ai
sudo hostnamectl set-hostname --pretty "Area58 Neural AI"
```

### 4.4 GRUB — profile/grub/grub.cfg

Rinominare la voce di menu:
```
menuentry "Area58 Neural AI (Live)" { ... }
```

### 4.5 Branding visivo

- `airootfs/usr/share/backgrounds/area58.jpg` (wallpaper dark, emblema
  metallico con rete neurale ambra)
- `airootfs/usr/share/icons/hicolor/*/apps/area58.png` (icone generate
  da master 1024 px con scripts/build-icons.sh)
- Tema SDDM personalizzato con logo
- (Opzionale) splash Plymouth: `plymouth-theme-area58`

---

## 5. Pacchetti — profile/packages.x86_64

### Audio / Pro
```
pipewire pipewire-jack wireplumber realtime-privileges
ardour carla calf lsp-plugins x42-plugins zynaddsubfx
surge-xt dexed mixxx lmms qjackctl sonic-pi plugdata sfizz
```

### Desktop
```
plasma-desktop plasma-wayland-session plasma-x11-session sddm
konsole dolphin plank kvantum ark gwenview kate firefox
```

### AI / Sistema
```
ollama python-pip git base-devel calamares
```

**Aggiungere una categoria per volta** (audio → desktop → AI), con rebuild
e test dopo ognuna, per isolare eventuali rotture.

---

## 6. Tuning pro-audio (airootfs)

### 6.1 airootfs/etc/security/limits.d/99-audio.conf

```
@realtime - rtprio 98
@realtime - memlock unlimited
@realtime - nice -19
```

### 6.2 airootfs/etc/sysctl.d/90-audio.conf

```
vm.swappiness=10
```

### 6.3 Kernel cmdline (grub.cfg)

Aggiungere `threadirqs` alla riga `APPEND`.

Nota: con PipeWire non serve il kernel-rt per uso semi-professionale.
Opzionale: compilare `linux-rt` in repo custom.

### 6.4 Config PipeWire utente (skel)

`airootfs/etc/skel/.config/pipewire/pipewire.conf.d/10-quantization.conf`:
```
context.properties = {
  default.clock.quantum = 128
  default.clock.rate = 48000
}
```

---

## 7. Desktop KDE + Dock

**Punto chiave:** Plank è X11-only, non funziona su Plasma 6 Wayland.
Decisione di progetto: **default X11** (per Plank) — documentare nel
benvenuto/README della distro.

### 7.1 Autostart Plank

`airootfs/etc/skel/.config/autostart/plank.desktop`:
```ini
[Desktop Entry]
Type=Application
Name=Plank Dock
Exec=plank
X-GNOME-Autostart-enabled=true
```

### 7.2 Sessione di default SDDM

Configurare SDDM per avviare la sessione X11 di Plasma di default.

### 7.3 Tema

- Kvantum come theme engine
- Wallpaper di default dal branding
- Bash/zsh rc minimi nello skel

---

## 8. Stack AI

### 8.1 Ollama (backend server)

Pacchetto Arch ufficiale + unit abilitato nel build:
```bash
systemctl enable ollama
```

### 8.2 Frontend browser — due opzioni incluse

1. **Open WebUI** — interfaccia stile ChatGPT su `localhost:8080`,
   inferenza via Ollama. Da AUR o container
2. **WebLLM (MLC)** — modelli DENTRO il browser via WebGPU
   (WebGPU → Vulkan funziona anche su 680M). Predisporre un
   bookmark/app Chromium verso la demo self-hosted

### 8.3 Script setup modelli — airootfs/usr/local/bin/area58-setup-model

```bash
#!/bin/bash
# Area58 Neural AI — selezione e download modelli AI locale
set -e

echo "=== Area58 Neural AI — Setup Modelli ==="
echo "1) Gemma 2 2B      (leggero, ~1.6 GB)"
echo "2) Llama 3.2 3B    (medio, ~2 GB)"
echo "3) Mistral 7B Q4   (pesante, ~4 GB — richiede 16 GB RAM)"
read -rp "Scelta [1-3]: " c

case "$c" in
  1) MODEL="gemma2:2b" ;;
  2) MODEL="llama3.2:3b" ;;
  3) MODEL="mistral:7b-instruct-q4_0" ;;
  *) echo "Scelta non valida"; exit 1 ;;
esac

echo "Download $MODEL ..."
ollama pull "$MODEL"
echo "Fatto. Interfaccia web: http://localhost:8080"
```

`chmod +x` sul file nel repo. Lo script si offre al primo avvio
(autostart o messaggio MOTD).

### 8.4 Nota RAM (16 GB con iGPU)

- Modelli 2B–3B: fluidi
- Mistral 7B Q4: fattibile ma al limite (RAM condivisa con iGPU)
- I modelli NON vanno inclusi nella ISO (dimensioni) — solo lo script

---

## 9. Installer Calamares

```bash
# aggiungere a packages.x86_64
calamares
```

- Configurare `/etc/calamares/modules/`:
  partizioni, utenti, machine-id, displaymanager
- Abilitare launcher desktop
- Test installazione completa in VM prima di ogni release

---

## 10. Build e test

```bash
# build
sudo ./profile/build.sh -v -w work -o out/

# checksum
sha256sum out/*.iso > out/SHA256SUMS

# test QEMU
qemu-system-x86_64 -enable-kvm -m 4096 -cdrom out/*.iso
```

Dimensione target ISO: **≤ 4 GB** (escludere soundfont enormi e modelli).

---

## 11. CI/CD — .github/workflows/build.yml

```yaml
name: build-iso
on:
  push:
    tags: ["v*"]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    container: archlinux:base-devel
    steps:
      - uses: actions/checkout@v4
      - name: Setup archiso
        run: |
          pacman -Syu --noconfirm archiso
      - name: Build ISO
        run: |
          cd profile
          ./build.sh -v -w /tmp/work -o ../out/
      - name: Checksum
        run: |
          cd out && sha256sum *.iso > SHA256SUMS
      - name: Release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            out/*.iso
            out/SHA256SUMS
```

---

## 12. Sicurezza (checklist da cybersicurezza)

- [ ] Solo `.safetensors`, mai `.pt`/`.pth`/`.ckpt` (pickle = RCE al load)
- [ ] Modelli solo da repo ufficiali (ollama.com, leejet, city96, Comfy-Org)
- [ ] Verifica hash dove disponibile
- [ ] Servizi AI in container / utente dedicato, non con privilegi di lavoro
- [ ] Chiave GPG dedicata al progetto (separata da quella personale)
      per firmare release e eventuali repo custom
- [x] Dominio registrato: **area58.it**
- [ ] Tutto in locale: prompt e dati non escono mai dalla rete —
      argomento di vendita della distro

---

## 13. Roadmap / Checklist avanzamento

| # | Fase | Deliverable | Stato |
|---|------|-------------|-------|
| 1 | Ambiente di build | Repo git + build stock OK | 🚧 |
| 2 | Pacchettizzazione | `packages.x86_64` completo | ☐ |
| 3 | Tuning pro-audio | limits.d, sysctl.d, threadirqs | ☐ |
| 4 | Desktop KDE + dock | X11 + Plank autostart + tema | ☐ |
| 5 | Stack AI | Ollama + Open WebUI + script modelli | ☐ |
| 6 | Installer | Calamares configurato e testato | ☐ |
| 7 | CI/CD | GitHub Actions + release SHA256 | ☐ |
| 8 | Branding | os-release, GRUB, wallpaper, SDDM | 🚧 |
| 9 | Rilascio v0.1 | ISO pubblica + GPG | 🚧 |

---

## 14. Rischi e mitigazioni

| Rischio | Mitigazione |
|---------|-------------|
| Plank incompatibile Wayland | Default sessione X11, documentato |
| 680M gfx1035 non in ROCm | WebLLM via WebGPU/Vulkan; Ollama su CPU |
| RAM 16 GB con Mistral 7B | Quantizzazioni Q4, script modelli opzionale |
| ISO > 4 GB | Escludere soundfont enormi, modelli fuori ISO |
| Hostname/underscore rifiutato da systemd | Statico con trattini + PRETTY_HOSTNAME |
| Build su host non-Arch (es. Mint) | Build solo su Arch: mini PC Ryzen di riferimento |

---

## 15. Conversione della roadmap in PDF

```bash
sudo pacman -S pandoc texlive-xetex texlive-fontsrecommended
pandoc docs/roadmap.md -o roadmap.pdf \
  --pdf-engine=xelatex -V geometry:margin=2.2cm \
  -V mainfont="DejaVu Sans" -V fontsize=11pt --toc
```

Alternativa leggera: `pandoc` → HTML → browser → Ctrl+P → PDF.

---

*Prossima azione: lunedì — Arch sul mini PC Ryzen, poi `bash fase1.sh`
per la prima build stock.*
MIOEOF
