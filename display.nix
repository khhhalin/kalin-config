{ config, pkgs, lib, ... }:

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
  programs.niri.enable = true;

  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings.waylandsessions =
    "${config.programs.niri.package}/share/wayland-sessions";

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # ── XDG portals ───────────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config.niri."org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
  };

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

}