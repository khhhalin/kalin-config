{ pkgs, lib, waydroid_script, ... }:

let
  meta = import ./meta.nix;
in
{
  # ── Audio ──────────────────────────────────────────────────────────
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # ── Storage ────────────────────────────────────────────────────────
  services.udisks2.enable = true;  # automount USB drives

  # ── Bluetooth (toggle in meta.nix) ────────────────────────────────
  hardware.bluetooth.enable = meta.enableBluetooth;
  services.blueman.enable  = meta.enableBluetooth;

  # ── Firmware updates ───────────────────────────────────────────────
  services.fwupd.enable = true;

  # ── File manager ───────────────────────────────────────────────────
  programs.thunar = {
    enable = true;
    plugins = [ pkgs.thunar-archive-plugin pkgs.thunar-volman ];
  };
  programs.xfconf.enable = true;
  services.gvfs.enable    = true;
  services.tumbler.enable = true;

  # ── Apps (toggles in meta.nix) ─────────────────────────────────────
  programs.steam.enable   = meta.enableSteam;

  virtualisation.waydroid = lib.mkIf meta.enableWaydroid {
    enable  = true;
    package = pkgs.waydroid-nftables;
  };

  # ── System packages ────────────────────────────────────────────────
  environment.systemPackages = with pkgs;
    [
      # build tools
      gnumake bison gcc binutils file flex

      # desktop
      xwayland-satellite file-roller xdg-utils

      # screenshots + clipboard + screen-share region picker
      grimblast slurp

      # brightness / audio / media
      pamixer playerctl

      # idle + lock
      # swaylock and swayidle live in rice-packages.nix

      # notifications + tray
      libnotify networkmanagerapplet

      vivaldi
      discord
    ]
    # waydroid helpers (only when enabled)
    ++ lib.optionals meta.enableWaydroid [
      waydroid-nftables
      waydroid_script.packages.${pkgs.stdenv.hostPlatform.system}.waydroid_script
      lzip
    ];

}
