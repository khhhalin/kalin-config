{ pkgs, ... }:

{
  programs.zsh.enable = true;

  # Handy baseline tools for interactive shells.
  environment.systemPackages = with pkgs; [
    git curl wget gnupg openssh
    unzip zip
    rsync
    jq ripgrep fd
  ];
}
