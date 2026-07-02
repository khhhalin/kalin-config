# NixOS Config

Minimal NixOS config with **niri** (Wayland compositor), **kanata** (keyboard remapper), and **Quickshell** (QML panel). No Home Manager — dotfiles live in `~/.config/`.

## Quick start for a friend

```bash
# 1. Clone this repo
git clone <url> ~/home-config && cd ~/home-config

# 2. Edit meta.nix — this is the ONLY file you need to touch
#    Change hostName, userName, timeZone, keyboard layout, toggle features…
nano meta.nix

# 3. Copy your hardware config
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# 4. Build & switch
sudo nixos-rebuild switch --flake .#YourHostName
```

## What to change in `meta.nix`

| Field                | What it does                  | Example               |
|----------------------|-------------------------------|------------------------|
| `hostName`           | Machine name & flake output   | `"MyLaptop"`           |
| `userName`           | Your login name               | `"alex"`               |
| `timeZone`           | System timezone               | `"America/New_York"`   |
| `xkb.layout`         | Keyboard layout               | `"us"`                 |
| `enableSteam`        | Install Steam                 | `false`                |
| `enableWaydroid`     | Android apps via Waydroid     | `false`                |
| `enableBluetooth`    | Bluetooth + Blueman           | `false`                |
| `enableLookingGlass` | Looking Glass KVM relay       | `false`                |

## File layout

One file per domain — `flake.nix` imports them all.

```
flake.nix                 ← entry point; passes meta into every module
meta.nix                  ← ★ personalize here ★
users.nix                 ← user account definition
hardware-configuration.nix← generated; do not edit by hand

system.nix                ← boot, nix daemon/GC, network, time+SSH, fonts, stateVersion
hardware.nix              ← audio (pipewire), bluetooth, fwupd/udisks2, Wine, Looking Glass
display.nix               ← niri + kalin-wm, ly, locale/keyboard, xdg portals, session
desktop.nix               ← all packages, zsh/git, thunar, nix-ld, steam/waydroid, quickshell
containers.nix            ← podman/distrobox, distro helpers, .deb mime handler

scripts/                  ← shell scripts embedded by modules (e.g. distrobox.sh)
quickshell/               ← QML panel files (deployed to /etc/xdg/quickshell/)
```

## Dotfiles (`~/.config/`)

The system config provides packages and services. All user preferences live as regular dotfiles:

| Dotfile                         | What                                  |
|---------------------------------|---------------------------------------|
| `~/.config/niri/config.kdl`     | Window manager (no keybinds — kanata) |
| `~/.config/kanata/config.kbd`   | All keybinds via niri IPC             |
| `~/.config/foot/foot.ini`       | Terminal emulator                     |
| `~/.config/fuzzel/fuzzel.ini`   | App launcher                          |
| `~/.config/swaylock/config`     | Lock screen                           |
| `~/.config/starship.toml`       | Shell prompt (auto-detected)          |

## Keybind cheatsheet (kanata → niri IPC)

| Key              | Action              |
|------------------|----------------------|
| `Win` (tap)      | Open launcher        |
| `Win` (hold)     | Activate niri layer  |
| `Win+H/J/K/L`   | Focus left/down/up/right |
| `Win+Shift+HJKL` | Move window          |
| `Win+Q`          | Close window         |
| `Win+F`          | Maximize column      |
| `Win+Shift+F`    | Fullscreen           |
| `Win+T`          | Toggle floating      |
| `Win+E`          | File manager         |
| `Win+B`          | Browser              |
| `Win+Enter`      | Terminal             |
| `Win+1–5`        | Workspace 1–5        |
| `Win+Shift+1–5`  | Move to workspace    |
| `Win+S`          | Screenshot (noop solo)|
| `Win+Shift+S`    | Screenshot           |
| `PrtSc`          | Screenshot           |
