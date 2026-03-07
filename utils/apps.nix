{ pkgs, lib, ... }:

let
  meta = import ../meta.nix;
in
{
  programs.steam.enable = meta.enableSteam;

  virtualisation.waydroid = lib.mkIf meta.enableWaydroid {
    enable = true;
    package = pkgs.waydroid-nftables;
  };
}
