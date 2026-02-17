{ config, lib, pkgs, ... }:

let
  meta = import ./meta.nix;
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = meta.hostName;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = meta.timeZone;
  services.timesyncd.enable = true;

  # Basic remote access (firewall stays closed unless you open it).
  services.openssh = {
    enable = true;
    openFirewall = false;
  };

  # Automatic cleanup to avoid the store growing forever.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # DO NOT change this lightly; see the NixOS manual entry for `system.stateVersion`.
  system.stateVersion = meta.stateVersion;
}
