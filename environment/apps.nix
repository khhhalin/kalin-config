{ pkgs, lib, ... }:

let
  meta = import ../configuration/meta.nix;
in
{
  services.flatpak.enable = true;

  programs.steam.enable = meta.enableSteam;

  virtualisation.waydroid = lib.mkIf meta.enableWaydroid {
    enable = true;
    package = pkgs.waydroid-nftables;
  };
}
