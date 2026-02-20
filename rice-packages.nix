{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ── Compositor / shell ───────────────────────────────────────────
    quickshell      # qs binary used for winbar and winmenu layershell UIs
    swaylock        # lock screen invoked via Super+Alt+L in niri binds
    swayidle        # idle daemon for auto-lock / monitor blanking

    # ── Terminal ─────────────────────────────────────────────────────
    foot            # Wayland terminal used by binds and winbar btop launches

    # ── Launcher ─────────────────────────────────────────────────────
    fuzzel          # fallback app launcher when quickshell menu is unavailable

    # ── Monitoring ───────────────────────────────────────────────────
    btop            # system monitor opened from winbar stats and battery panes

    # ── Clipboard ────────────────────────────────────────────────────
    cliphist        # clipboard history backend for winbar list/decode actions
    wl-clipboard    # wl-copy / wl-paste used by cliphist and wl-paste watcher

    # ── Notifications ────────────────────────────────────────────────
    dunst           # notification daemon and dunstctl CLI for winbar popups

    # ── Audio ────────────────────────────────────────────────────────
    pavucontrol     # GUI mixer launched from audio popup

    # ── Brightness ───────────────────────────────────────────────────
    brightnessctl   # XF86 brightness keys handled in niri binds

    # ── Screenshots ──────────────────────────────────────────────────
    grim            # Wayland screenshot tool for manual captures
    slurp           # region selector used with grim screenshots

    # ── Keyboard ─────────────────────────────────────────────────────
    kanata-with-cmd # keyboard remapper referenced by Kanata start-menu comment

    # ── Editors ──────────────────────────────────────────────────────
    vscode          # VS Code for F11 bind (code)

    # ── Utilities ────────────────────────────────────────────────────
    python3         # runs app-list.py indexer from quickshell configs
    orca            # screen reader toggled by Super+Alt+S bind
  ];
}
