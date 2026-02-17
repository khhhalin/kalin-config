{ config, lib, pkgs, ... }:

let
  meta = import ./meta.nix;
in
{
  # ── Nix ────────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # ── Boot ───────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Network ────────────────────────────────────────────────────────
  networking.hostName              = meta.hostName;
  networking.networkmanager.enable = true;
  networking.firewall.enable       = true;

  # ── Time ───────────────────────────────────────────────────────────
  time.timeZone             = meta.timeZone;
  services.timesyncd.enable = true;

  # ── SSH (firewall stays closed unless you open it) ────────────────
  services.openssh = {
    enable       = true;
    openFirewall = false;
  };

  # ── Garbage collection ─────────────────────────────────────────────
  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # ── DO NOT CHANGE (see NixOS manual → system.stateVersion) ────────
  system.stateVersion = meta.stateVersion;
}
