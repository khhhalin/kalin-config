{ pkgs, ... }:

let
  # `nerd-fonts` replaced `nerdfonts` in newer nixpkgs; keep compatibility.
  hackNerdFont =
    if builtins.hasAttr "nerd-fonts" pkgs
    then pkgs."nerd-fonts".hack
    else pkgs.nerdfonts.override { fonts = [ "Hack" ]; };
in
{
  # Ensure apps (including foot) can resolve font names via fontconfig.
  fonts.fontconfig.enable = true;

  home.packages = [
    hackNerdFont
  ];
}
