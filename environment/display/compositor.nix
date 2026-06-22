{ config, pkgs, inputs, ... }:

{
  # Enable seatd for Wayland compositor access to DRM/input devices
  services.seatd.enable = true;

  programs.niri = {
    enable = true;
    # Needed for native `include` support in config.kdl.
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
  };

  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings.waylandsessions = "/etc/wayland-sessions";

  environment.etc."wayland-sessions/niri.desktop".text = ''
    [Desktop Entry]
    Name=niri
    Comment=Wayland compositor (niri)
    Exec=${config.programs.niri.package}/bin/niri
    DesktopNames=niri
    Type=Application
  '';

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
