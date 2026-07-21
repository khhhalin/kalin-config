# NixOS Config

Personal NixOS config for **KalinBook**. Primary session: **kalin-wm**
(infinite-canvas Wayland compositor, dwl fork) + Quickshell bar; **niri** is
kept as a fallback session. No Home Manager — dotfiles live in
`~/environment/dotfiles`, symlinked into `~/.config/`.

## Quick start for a friend

```bash
# 1. Clone this repo
git clone <url> ~/home-config && cd ~/home-config

# 2. Edit meta.nix — this is the ONLY file you need to touch
#    Change hostName, userName, timeZone, keyboard layout, paths, features…
nano meta.nix

# 3. Copy your hardware config
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# 4. Build & switch
sudo nixos-rebuild switch --flake .#YourHostName
```

## What to change in `meta.nix`

| Field             | What it does                  | Example              |
|-------------------|-------------------------------|----------------------|
| `hostName`        | Machine name & flake output   | `"MyLaptop"`         |
| `userName`        | Your login name               | `"alex"`             |
| `timeZone`        | System timezone               | `"America/New_York"` |
| `xkb.layout`      | Keyboard layout               | `"us"`               |
| `dirs.*`          | Project working-tree paths    | `dirs.kalinWm`       |
| `enableSteam`     | Install Steam                 | `false`              |
| `enableWaydroid`  | Android apps via Waydroid     | `false`              |
| `enableBluetooth` | Bluetooth + Blueman           | `false`              |

## File layout

One file per domain — `flake.nix` imports them all.

```
flake.nix                  ← entry point; passes meta into every module
meta.nix                   ← ★ personalize here ★ (incl. dirs.* paths)
users.nix                  ← user account definition
hardware-configuration.nix ← generated; do not edit by hand

system.nix                 ← boot, nix daemon/GC, network, time+SSH, fonts, stateVersion
hardware.nix               ← audio (pipewire), bluetooth, fwupd/udisks2, Wine
display.nix                ← kalin-wm + niri sessions, ly, locale/keyboard, xdg portals
desktop.nix                ← packages, zsh aliases, nautilus, nix-ld, steam/waydroid
containers.nix             ← podman/distrobox, distro helpers, .deb handler
kalin-tmux.nix             ← persistent tmux server (user service)
claude-tty.nix             ← ttyd web terminal into a Claude tmux session
fleet-deck.nix             ← fleet-deck daemon (user service)

scripts/                   ← shell scripts embedded by modules (distrobox.sh, pkgs.sh)
```

## Everyday commands

Defined as zsh aliases in `~/.zshrc` (single source of truth — NixOS
deliberately sets no shell aliases):

- `kalin-rebuild` / `kalin-rebuild-build` — switch / build this config
  (always with `--override-input kalin-wm`, so the live working tree is used)
- `kalin-build`, `kalin-test` — build & unit-test kalin-wm
- `kalin-nested`, `kalin-tty`, `kalin-tty3` — run kalin-wm nested / on a TTY / on VT 3
- `kalin-vm-build`, `kalin-vm-run`, `kalin-vm-logs` — QEMU test VM
- `kalinwm` — dev launcher: current working-tree kalin-wm build on your TTY

## Keybinds

kalin-wm keybinds are compile-time: `code/config/config.h` in the kalin-wm
repo (reference: `obsidian/implementation/keybindings.md` there). niri's
binds live in `~/environment/dotfiles/niri/`.
