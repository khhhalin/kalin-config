{ pkgs, ... }:

{
  # xdg-desktop-portal-gnome DOES NOT work with niri: it checks for
  # org.gnome.Mutter.ServiceChannel at startup; niri doesn't expose
  # that interface, so gnome-portal logs "Non-compatible display server,
  # exposing settings only" and refuses to serve ScreenCast — every
  # single boot. The picker dialog never appears.
  #
  # xdg-desktop-portal-luminous uses zwlr-screencopy-v1, which niri
  # DOES implement, so ScreenCast + Screenshot work correctly.
  # (xdg-desktop-portal-wlr is NOT an option: it requires
  #  zwlr-output-management-v1 which niri intentionally omits.)
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-luminous  # ScreenCast + Screenshot via zwlr-screencopy
      pkgs.xdg-desktop-portal-gtk       # FileChooser, Access, Notification
    ];
    config.niri = {
      default = [ "luminous" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "luminous" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "luminous" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
    };
  };
}
