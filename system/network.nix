{ pkgs, ... }:

let
  meta = import ../configuration/meta.nix;
in
{
  networking.hostName = meta.hostName;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # WiFi GUI management
  programs.nm-applet.enable = true;
}
