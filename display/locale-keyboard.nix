{ ... }:

let
  meta = import ../meta.nix;
in
{
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
}
