{ pkgs, waydroid_script, ... }:

{
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  environment.systemPackages = [
    pkgs.waydroid-nftables
    waydroid_script.packages.${pkgs.system}.waydroid_script
    pkgs.lzip
  ];
}
