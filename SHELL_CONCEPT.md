# Shell / Panel Concept (Quickshell + niri)

This document captures the UI concept from the sketch: a simple per-monitor panel with an “Android-style” tray/quick-settings dropdown, plus a few workflow-oriented views (integrations, keybinds, niri helpers).

## Goals

- Keep a clean, low-noise panel on every monitor.
- Make “common toggles” fast (Wi‑Fi, Bluetooth, misc) via a dropdown/tray.
- Support multi-monitor workflows: everything should act on the *active screen*.
- Provide a small set of consistent keybindings (niri + shell actions).

## Layout

### Always-visible panel (per monitor)

- One panel per screen.
- Minimal default contents:
  - Left: small “status / menu” icons.
  - Middle: workspace list (e.g. `1 2 3 4 5`).
  - Right: clock.

### Expanded dropdown (active monitor only)

A tray-like dropdown expands from the panel (Android quick-settings vibe).

- Left column: category list
  - Wi‑Fi
  - Bluetooth
  - Misc
  - Keybinds
- Main area: detail view for the selected category.

## Interactions

- The dropdown opens on the currently focused monitor (active screen).
- The dropdown should behave like a transient UI:
  - Esc closes
  - clicking outside closes
  - opening it again focuses the existing instance (don’t spawn duplicates)

## Features by category

### Wi‑Fi

- Show current SSID + state.
- List networks (optional).
- Quick actions: toggle Wi‑Fi, open settings app (if you prefer).

### Bluetooth

- Show on/off.
- List paired devices (optional).
- Quick actions: toggle Bluetooth, connect/disconnect (optional).

### Misc

Suggested “cheap wins” that fit the sketch:

- Volume slider + output device selector
- Brightness slider (if laptop)
- Night light toggle
- Screenshot actions

### Keybinds

A searchable cheat sheet for your core workflow:

- Shell: open/close dropdown, open launcher, open terminal
- niri: overview, move/resize, workspace switching
- Optional: show kanata layer/state if you expose it

## Multi-monitor behavior

- Workspace list could be global (same on all monitors) or per-monitor.
- Screen list / navigation: quick way to jump focus to monitor 1/2/3.

## Implementation notes

- Quickshell QML can provide the per-screen panel by iterating `Quickshell.screens` (you already do this in home/quickshell/shell.qml).
- The dropdown should be a separate overlay window (e.g. another `PanelWindow` or popup) created only for the active screen.
- State model: a single “controller” holds:
  - which screen is active
  - whether dropdown is open
  - active category

## Open questions

1) Panel placement: is it intended to be **bottom** (as in sketch) or top? Your current QML anchors it to the top.

2) Workspace semantics:
- Should the workspace list be global (niri default feel) or per-output?
- Do you want workspace numbers only, or also app indicators?

3) Dropdown trigger:
- What key opens the dropdown? (You mention Alt+Tab dropdown; do you actually want Alt+Tab to open the tray, or should it be a different combo like Super+T?)

4) Settings sources:
- For Wi‑Fi/Bluetooth: should the shell directly toggle via NetworkManager/bluetoothd, or just launch a settings UI (simpler + more reliable)?

5) “Integrations” view:
- You wrote integrations (niri settings, tiles, root, vivaldi). Is the intent “quick shortcuts”, “system status”, or actual configuration editing?

6) Screenshot flow:
- You note per-screen screenshot with e-ink/softcopy/gray. Should this be a menu that calls specific screenshot commands?

If you answer (1) and (3), I can adjust home/quickshell/shell.qml to match the panel position and add a basic dropdown skeleton with category switching.
