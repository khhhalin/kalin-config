{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # shell prompt
    starship

    # core CLI
    git curl wget gnupg openssh
    unzip zip rsync
    jq ripgrep fd
    fastfetch
    tmux
  ];
}
