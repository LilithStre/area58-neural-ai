# Area58 Neural AI

**Arch-based live/installable Linux distribution — Pro Audio, KDE Plasma, Local AI.**
*Your prompts never leave your machine.*

---

## What is this?

Area58 Neural AI is a Linux distribution built with [archiso](https://gitlab.archlinux.org/archlinux/archiso)
on top of Arch Linux. It ships a complete creative workstation:

- 🎛️ **Pro Audio stack** — PipeWire + JACK, Ardour, Carla, LSP Plugins, Mixxx, Sonic Pi and more,
  with realtime tuning out of the box (`threadirqs`, `realtime-privileges`, tuned quantization)
- 🖥️ **KDE Plasma desktop** with a macOS-style dock (Plank, X11 session)
- 🤖 **Local AI** — Ollama backend + browser frontends (Open WebUI / WebLLM).
  Models are downloaded on demand, never bundled. No cloud, no telemetry.
- 💿 **Live + installer** — boot it, try it, install it with Calamares

## Status

🚧 **Work in progress** — v0.1 not released yet. Full project guide (Italian): [GUIDA-AREA58.md](GUIDA-AREA58.md)

| Phase | Deliverable | Status |
|-------|-------------|--------|
| Build environment | Stock ISO build | 🚧 |
| Package selection | Full audio/desktop/AI set | ☐ |
| Pro audio tuning | limits, sysctl, threadirqs | ☐ |
| KDE + dock | X11 + Plank + theme | ☐ |
| AI stack | Ollama + model setup script | ☐ |
| Installer | Calamares configured | ☐ |
| CI/CD | GitHub Actions releases | ☐ |
| Branding | os-release, GRUB, assets | 🚧 |
| v0.1 release | Public ISO + GPG signatures | ☐ |

## Hardware

Reference test bench: ACEMAGIC M1 (Ryzen 7 7735HS, Radeon 680M, 16 GB RAM).
The distribution is **not** tied to this hardware — any x86_64 UEFI machine works.
Low-RAM machines: pick the 2B model in the AI setup script and everything stays smooth.

## Build from source

Requires an Arch Linux host with `archiso`:

```bash
sudo pacman -S archiso
sudo ./profile/build.sh -v -w work -o out/
```

Test in QEMU:

```bash
qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cdrom out/*.iso
```

## Security notes

- Only `.safetensors` model formats, never pickle-based (`.pt`/`.pth`/`.ckpt`)
- Models pulled exclusively from official sources (ollama.com)
- Everything runs locally: prompts and data never leave the network

## License

TBD — will be decided before v0.1.

---

*Built with archiso. Powered by coffee and threadirqs.*
MIOEOF
