# Boot, nix daemon, networking, time, fonts — core system plumbing.
{ pkgs, meta, ... }:

{
  # ── Boot ──────────────────────────────────────────────────────────
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;  # keep the EFI partition from filling up
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Nix daemon ────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty = false;  # silence "Git tree is dirty" on every rebuild
  };
  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;  # Android Studio SDK components need this to install
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
    persistent = true;  # catch up on GC missed while asleep
  };
  nix.optimise.automatic = true;

  # ── Time & SSH ────────────────────────────────────────────────────
  time.timeZone = meta.timeZone;
  services.timesyncd.enable = true;
  services.openssh = {
    enable = true;
    openFirewall = false;
  };

  # ── Networking ────────────────────────────────────────────────────
  networking.hostName = meta.hostName;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  programs.nm-applet.enable = true;

  # ── Fonts ─────────────────────────────────────────────────────────
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
    ];
    enableDefaultPackages = true;
    fontconfig.enable = true;
  };

  # DO NOT CHANGE — see NixOS manual → system.stateVersion
  system.stateVersion = meta.stateVersion;
}
