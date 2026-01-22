{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default.extensions = with pkgs.vscode-extensions; [
      julialang.language-julia
    ];

    # userSettings = {
    #   "editor.fontSize" = 14;
    # };
  };
}
