{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
    };
  };

  environment.systemPackages = with pkgs; [
    # shell prompt
    starship

    # core CLI
    git gh curl wget gnupg openssh
    unzip zip rsync
    jq ripgrep fd
    fastfetch   # neofetch replacement (neofetch is unmaintained)
    tmux
  ];
}
