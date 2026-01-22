# Single source of truth for your colors.
#
# This is a Base16 (16-color) scheme, which is the most interoperable format
# across Nix theming tools (nix-colors, Stylix, many app templates).
#
# Change these values to your preferred palette.
{
  slug = "kalin";
  name = "Kalin";
  author = "kalin";

  # Variant is used by some apps to pick dark/light behavior.
  # Use "dark" or "light".
  variant = "dark";

  # Base16 palette. Values are hex WITHOUT leading '#'.
  palette = {
    # background / surface
    base00 = "0b0f14";
    base01 = "101826";
    base02 = "172233";
    base03 = "243247";

    # foreground
    base04 = "b3bcc7";
    base05 = "d6dde6";
    base06 = "e7eef7";
    base07 = "ffffff";

    # accents (pick your own semantics here)
    base08 = "ff5c57"; # error
    base09 = "ff9f43"; # warning
    base0A = "f3f99d"; # highlight
    base0B = "5af78e"; # success
    base0C = "9aedfe"; # info
    base0D = "57c7ff"; # primary/accent
    base0E = "ff6ac1"; # secondary
    base0F = "b18aff"; # tertiary
  };
}
