{ pkgs, ... }:

{
  programs.zsh.enable = true;

  # Keep the user's login shell aligned with the enabled system shell.
  users.users.kalin.shell = pkgs.zsh;
}
