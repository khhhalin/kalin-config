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

| Field              | What it does                          | Example               |
|--------------------|---------------------------------------|------------------------|
| `hostName`         | Machine name & flake output           | `"MyLaptop"`           |
| `userName`         | Your login name                       | `"alex"`               |
| `timeZone`         | System timezone                       | `"America/New_York"`   |
| `xkb.layout`      | Keyboard layout                       | `"us"`                 |
| `enableSteam`      | Install Steam                         | `false`                |
| `enableWaydroid`   | Android apps via Waydroid             | `false`                |
| `enableBluetooth`  | Bluetooth + Blueman                   | `false`                |
| `accentColor`      | Theme accent (niri, fuzzel, foot…)    | `"#7aa2f7"`            |
| `bgColor`          | Background color                      | `"#1a1b26"`            |
| `gaps`             | Window gaps in px                     | `12`                   |
| `cursorTheme`      | Cursor theme name                     | `"Bibata-Modern-Ice"`  |

## File layout

```
flake.nix            ← entry point
meta.nix             ← ★ personalize here ★
configuration.nix    ← imports everything, defines user

nix/                 ← nix settings + stateVersion (rarely changed)
system/              ← boot, network, time, fonts, ssh, gc
display/             ← locale/keyboard, niri, portals, fonts, power, security
shell/               ← zsh, CLI tools, starship
utils/               ← audio, bluetooth, firmware, file manager, apps, packages
containers/          ← podman/distrobox, packages, mime associations
rice-packages/       ← compositor/desktop packages + power profiles

quickshell/          ← QML panel files (deployed to /etc/xdg/quickshell/)
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
