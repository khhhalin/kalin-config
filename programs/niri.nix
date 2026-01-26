{ config, lib, pkgs, ... }:

{
  # Declarative niri configuration based on upstream `default-config.kdl.nix`.
  # We prefer the validated `programs.niri.settings` tree rather than
  # performing imperative edits on the generated KDL.

  # Allow home-manager to overwrite an existing generated config.kdl
  xdg.configFile."niri/config.kdl".force = true;

  programs.niri.settings = {
    # Prefer server-side decorations over CSD when possible.
    prefer-no-csd = true;

    # Keyboard input
    input = {
      keyboard = {
        xkb = {
          layout = "pl"; # use Polish layout inside niri
        };
        track-layout = "global";
      };
    };

    # Keep the Mod+Space -> DMS Spotlight bind.
    binds = {
      "Mod+Space" = {
        action = { spawn = [ "dms" "ipc" "call" "spotlight" "toggle" ]; };
        "hotkey-overlay" = { title = "App Launcher: DMS"; };
      };
    };

    # We purposely do not add spawn-at-startup entries here so DMS can manage
    # wallpaper/autostarts itself.
  };
}
