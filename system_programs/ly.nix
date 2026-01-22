{ config, ... }:

{
  services.xserver.enable = true;
  services.displayManager.ly.enable = true;

  # Ly session discovery
  # Ly’s generated session directory may contain symlinks; point directly at
  # niri’s session directory to ensure it appears in the session list.
  services.displayManager.ly.settings.waylandsessions =
    "${config.programs.niri.package}/share/wayland-sessions";
}
