{ pkgs, lib, waydroid_script, ... }:

let
  meta = import ../meta.nix;
in
{
  environment.systemPackages = with pkgs;
    [
      # build tools
      gnumake bison gcc binutils file flex

      # desktop
      xwayland-satellite file-roller xdg-utils

      # screenshots + clipboard
      grimblast slurp

      # brightness / audio / media
      pamixer playerctl

      # notifications + tray
      libnotify networkmanagerapplet

      vivaldi
      obsidian
      ghostty
      helix

      # ── Discord ────────────────────────────────────────────────────
      # vesktop: Vencord-based client with native PipeWire screen share.
      # It has its own WebRTC implementation and does NOT depend on the
      # xdg-desktop-portal ScreenCast call completing correctly — the
      # most reliable option on any Wayland compositor.
      vesktop

      #
      #globalprotect-openconnect
    ]
    # waydroid helpers (only when enabled)
    ++ lib.optionals meta.enableWaydroid [
      waydroid-nftables
      waydroid_script.packages.${pkgs.stdenv.hostPlatform.system}.waydroid_script
      lzip
    ];
}
