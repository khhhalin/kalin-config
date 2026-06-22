{ pkgs, lib, inputs, ... }:

let
  meta = import ../configuration/meta.nix;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # Plain installs only: anything that needs no further config beyond being
  # on PATH. Packages that come with their own options/services/overrides
  # live in their topical module (shell.nix, rice/default.nix, …).
  environment.systemPackages = with pkgs;
    [
      # ── Build tools ───────────────────────────────────────────────
      gnumake bison gcc binutils file flex

      # ── Wayland session / compositor ──────────────────────────────
      xwayland-satellite swaylock swayidle swaybg

      # ── Launchers & terminals ─────────────────────────────────────
      fuzzel ghostty foot

      # ── Screenshots + clipboard ───────────────────────────────────
      grimblast grim slurp cliphist wl-clipboard

      # ── Audio / brightness / media ────────────────────────────────
      pamixer playerctl pavucontrol brightnessctl

      # ── Notifications + tray ──────────────────────────────────────
      libnotify dunst networkmanagerapplet

      # ── Connectivity ──────────────────────────────────────────────
      blueman openconnect

      # ── Keyboard ──────────────────────────────────────────────────
      kanata-with-cmd

      # ── File management ───────────────────────────────────────────
      file-roller xdg-utils mutagen

      # ── Browsers ──────────────────────────────────────────────────
      vivaldi
      inputs.zen-browser.packages.${system}.default

      # ── Editors ───────────────────────────────────────────────────
      helix vscode

      # ── Productivity ──────────────────────────────────────────────
      obsidian qbittorrent

      # ── Monitoring ────────────────────────────────────────────────
      btop

      # ── Gaming ────────────────────────────────────────────────────
      prismlauncher jdk21

      # ── Development ───────────────────────────────────────────────
      julia claude-code github-desktop

      # ── Qt6 runtime ───────────────────────────────────────────────
      qt6.qtbase qt6.qtdeclarative qt6.qtwayland qt6.qt5compat

      # ── Graphics ──────────────────────────────────────────────────
      libGL

      # ── Accessibility / scripting ─────────────────────────────────
      python3 orca

      # ── Communication ─────────────────────────────────────────────
      # vesktop: Vencord-based client with native PipeWire screen share.
      # It has its own WebRTC implementation and does NOT depend on the
      # xdg-desktop-portal ScreenCast call completing correctly — the
      # most reliable option on any Wayland compositor.
      vesktop
    ]
    # waydroid helpers (only when enabled)
    ++ lib.optionals meta.enableWaydroid [
      waydroid-nftables
      inputs.waydroid_script.packages.${system}.waydroid_script
      lzip
    ];
}
