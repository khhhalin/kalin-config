{ pkgs, lib, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  # Prefer nixpkgs for Hyprland + plugins: faster (binary cache) and version-aligned.
  hyprlandPkg = pkgs.hyprland;

  hyprscrolling = lib.attrByPath [ "hyprlandPlugins" "hyprscrolling" ] null pkgs;

  caelestiaPkg =
    if inputs ? caelestia_shell then
      let
        packages = inputs.caelestia_shell.packages.${system} or {};
      in
      packages.with-cli or packages.default or packages.caelestia-shell or null
    else
      null;

  hyprConfigPath = "/etc/xdg/hypr/hyprland-caelestia.conf";
  hyprConfigText = ''
    # Hyprland session for Caelestia Shell.
    # This file is referenced explicitly by the session entry.

    # Plugin loading (Hyprland plugin path).
    ${lib.optionalString (hyprscrolling != null) "plugin = ${hyprscrolling}/lib/libhyprscrolling.so"}

    ${lib.optionalString (hyprscrolling != null) ''
      general {
        layout = scrolling
      }
    ''}

    # Keep the config minimal; Caelestia Shell expects you to manage most UX from the shell.
    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
    }

    # Emergency exit (in case your binds aren't set up yet).
    bind = SUPER SHIFT, E, exit

    # Start Caelestia Shell (recommended: install the with-cli package for full functionality).
    ${if caelestiaPkg != null then "exec-once = caelestia-shell" else ""}
  '';

  sessionDesktop = ''
    [Desktop Entry]
    Name=Hyprland (Caelestia)
    Comment=Hyprland with hyprscrolling plugin and optional shell
    Exec=${hyprlandPkg}/bin/start-hyprland --config ${hyprConfigPath}
    DesktopNames=Hyprland
    Type=Application
  '';
in
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = hyprlandPkg;
  };

  environment.systemPackages =
    (lib.optional (hyprscrolling != null) hyprscrolling)
    ++ (lib.optional (caelestiaPkg != null) caelestiaPkg);

  environment.etc."xdg/hypr/hyprland-caelestia.conf".text = hyprConfigText;

  # Custom session entry so `ly` can list it regardless of where Hyprland ships
  # its default session file.
  environment.etc."wayland-sessions/hyprland-caelestia.desktop".text = sessionDesktop;
}
