{ config, pkgs, lib, niri, ... }:

let
  meta = import ./meta.nix;
in
{
  # ── Fonts ──────────────────────────────────────────────────────────
  fonts = {
    enableDefaultPackages = true;
    fontconfig.enable = true;
  };

  services.upower.enable = true;

  # ── Locale & keyboard ─────────────────────────────────────────────
  i18n.supportedLocales = meta.supportedLocales;
  i18n.defaultLocale    = meta.defaultLocale;

  services.xserver.enable = true;
  services.xserver.xkb = {
    layout  = meta.xkb.layout;
    model   = meta.xkb.model;
    variant = meta.xkb.variant;
    options = meta.xkb.options;
  };
  console.useXkbConfig = true;

  environment.variables = {
    XKB_DEFAULT_LAYOUT  = meta.xkb.layout;
    XKB_DEFAULT_MODEL   = meta.xkb.model;
    XKB_DEFAULT_VARIANT = meta.xkb.variant;
    XKB_DEFAULT_OPTIONS = meta.xkb.options;
  };

  # ── Compositor: niri (Wayland) ─────────────────────────────────────
  programs.niri = {
    enable = true;
    # Needed for native `include` support in config.kdl.
    package = niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
  };

  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings.waylandsessions =
    "${config.programs.niri.package}/share/wayland-sessions";

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # ── XDG portals ───────────────────────────────────────────────────
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
      default                                          = [ "luminous" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast"         = [ "luminous" ];
      "org.freedesktop.impl.portal.Screenshot"         = [ "luminous" ];
      "org.freedesktop.impl.portal.FileChooser"        = [ "gtk" ];
      "org.freedesktop.impl.portal.Access"             = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification"       = [ "gtk" ];
    };
  };

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

}