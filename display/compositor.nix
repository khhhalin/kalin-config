{ config, pkgs, niri, ... }:

{
  programs.niri = {
    enable = true;
    # Needed for native `include` support in config.kdl.
    package = niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
  };

  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings.waylandsessions =
    "${config.programs.niri.package}/share/wayland-sessions";

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
