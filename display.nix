{ config, pkgs, lib, ... }:

let
  meta = import ./meta.nix;
in
{
  fonts = {
    enableDefaultPackages = true;
    fontconfig.enable = true;
  };

  services.upower.enable = true;

  # Keep TTY/LY and graphical sessions on the same keyboard layout.
  i18n.supportedLocales = meta.supportedLocales;
  i18n.defaultLocale = meta.defaultLocale;

  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = meta.xkb.layout;
    model = meta.xkb.model;
    variant = meta.xkb.variant;
    options = meta.xkb.options;
  };

  console.useXkbConfig = true;
  environment.variables = {
    XKB_DEFAULT_LAYOUT = meta.xkb.layout;
    XKB_DEFAULT_MODEL = meta.xkb.model;
    XKB_DEFAULT_VARIANT = meta.xkb.variant;
    XKB_DEFAULT_OPTIONS = meta.xkb.options;
  };

  # Desktop session: niri (Wayland) + ly login + portals.
  programs.niri.enable = true;

  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings.waylandsessions =
    "${config.programs.niri.package}/share/wayland-sessions";

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];

    config.niri = {
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # GTK / cursor / icon theming (so apps don't look broken)
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    bibata-cursors
    gnome-themes-extra
  ];

  # Deploy quickshell config to /etc/xdg/quickshell
  environment.etc."xdg/quickshell/shell.qml".source        = ./quickshell/shell.qml;
  environment.etc."xdg/quickshell/Bar.qml".source           = ./quickshell/Bar.qml;
  environment.etc."xdg/quickshell/DropdownPanel.qml".source  = ./quickshell/DropdownPanel.qml;
  environment.etc."xdg/quickshell/NotificationPopup.qml".source = ./quickshell/NotificationPopup.qml;
  environment.etc."xdg/quickshell/Theme.qml".source         = ./quickshell/Theme.qml;
  environment.etc."xdg/quickshell/qmldir".source            = ./quickshell/qmldir;

  # niri config (no Home Manager): install a full config under /etc/xdg.
  # niri reads XDG config; /etc/xdg is part of XDG_CONFIG_DIRS on NixOS.
  environment.etc."xdg/niri/config.kdl".text = ''
    input {
      keyboard {
        xkb {
          layout "${meta.xkb.layout}"
          model "${meta.xkb.model}"
          variant "${meta.xkb.variant}"
          options "${meta.xkb.options}"
        }
        track-layout "global"
        repeat-delay 300
        repeat-rate 50
      }

      touchpad {
        tap
        natural-scroll
        dwt
        accel-speed 0.3
      }

      mouse {
        accel-speed 0.0
      }
    }

    prefer-no-csd

    // Autostart
    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "quickshell" "-p" "${meta.quickshellConfigPath}/shell.qml"
    spawn-at-startup "swayidle" "-w" "timeout" "300" "swaylock -f" "timeout" "600" "niri msg action power-off-monitors" "resume" "niri msg action power-on-monitors"
    spawn-at-startup "nm-applet" "--indicator"

    // Screenshots
    screenshot-path "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png"

    // Layout defaults
    layout {
      gaps 8
      default-column-width { proportion 0.5; }

      focus-ring {
        width 2
        active-color "#e94560"
        inactive-color "#2a2a4a"
      }

      border {
        off
      }
    }

    // Window rules
    window-rule {
      geometry-corner-radius 8 8 8 8
      clip-to-geometry true
    }

    // Keybindings
    binds {
      // Launcher (Win tap via kanata sends Mod+Space)
      Mod+Space       { spawn "fuzzel"; }

      // Apps
      Mod+T           { spawn "foot"; }
      Mod+E           { spawn "thunar"; }
      Mod+B           { spawn "firefox"; }

      // Window management
      Mod+Q           { close-window; }
      Mod+F           { maximize-column; }
      Mod+Shift+F     { fullscreen-window; }

      // Focus
      Mod+Left        { focus-column-left; }
      Mod+Right       { focus-column-right; }
      Mod+Up          { focus-window-or-workspace-up; }
      Mod+Down        { focus-window-or-workspace-down; }
      Mod+H           { focus-column-left; }
      Mod+L           { focus-column-right; }
      Mod+K           { focus-window-or-workspace-up; }
      Mod+J           { focus-window-or-workspace-down; }

      // Move windows
      Mod+Shift+Left  { move-column-left; }
      Mod+Shift+Right { move-column-right; }
      Mod+Shift+Up    { move-window-up-or-to-workspace-up; }
      Mod+Shift+Down  { move-window-down-or-to-workspace-down; }
      Mod+Shift+H     { move-column-left; }
      Mod+Shift+L     { move-column-right; }
      Mod+Shift+K     { move-window-up-or-to-workspace-up; }
      Mod+Shift+J     { move-window-down-or-to-workspace-down; }

      // Resize
      Mod+Minus       { set-column-width "-10%"; }
      Mod+Equal       { set-column-width "+10%"; }

      // Workspaces
      Mod+1           { focus-workspace 1; }
      Mod+2           { focus-workspace 2; }
      Mod+3           { focus-workspace 3; }
      Mod+4           { focus-workspace 4; }
      Mod+5           { focus-workspace 5; }
      Mod+Shift+1     { move-column-to-workspace 1; }
      Mod+Shift+2     { move-column-to-workspace 2; }
      Mod+Shift+3     { move-column-to-workspace 3; }
      Mod+Shift+4     { move-column-to-workspace 4; }
      Mod+Shift+5     { move-column-to-workspace 5; }

      // Monitors
      Mod+Shift+Comma  { move-column-to-monitor-left; }
      Mod+Shift+Period { move-column-to-monitor-right; }
      Mod+Comma        { focus-monitor-left; }
      Mod+Period       { focus-monitor-right; }

      // Screenshots
      Print           { screenshot; }
      Mod+Print       { screenshot-window; }
      Mod+Shift+Print { screenshot-screen; }

      // Session
      Mod+Shift+E     { quit; }
      Mod+Shift+P     { power-off-monitors; }
    }
  '';
}
