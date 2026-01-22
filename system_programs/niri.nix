{ pkgs, ... }:

{
  # Wayland / Niri baseline.
  programs.niri.enable = true;

  environment.sessionVariables = {
    # Helps Electron/Chromium apps prefer native Wayland (IME + scaling, etc.).
    NIXOS_OZONE_WL = "1";
  };

  # Desktop portals are required for file pickers, screenshots/screencast, `xdg-open`, etc.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    # Niri works well with the GNOME portal for screencasting.
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];

    # Avoid GNOME portal trying to use Nautilus as the file picker.
    config.niri = {
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
}
