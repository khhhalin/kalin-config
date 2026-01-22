{ config, pkgs, nix-colors, ... }:

{
  # Global colors: used by modules via `config.colorScheme.palette.base0X`.
  # Change the actual palette in `theme/scheme.nix`.
  colorScheme = import ./theme/scheme.nix;

  home.username = "kalin";
  home.homeDirectory = "/home/kalin";

  imports = [
    ./programs/foot.nix
    ./programs/fonts.nix
    ./programs/niri.nix
    ./programs/walltheme.nix
    ./programs/thunar.nix
    ./programs/cursor.nix
    ./programs/zsh.nix
    ./programs/starship.nix
    ./programs/vscode.nix
    ./programs/julia.nix
    ./programs/vivaldi.nix
  ];

  home.packages = [
    pkgs.unzip
    pkgs.texlive.combined.scheme-full
    pkgs.legcord

  ];

  home.stateVersion = "24.11";
}
