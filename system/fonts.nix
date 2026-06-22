{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
    ];

    enableDefaultPackages = true;
    fontconfig.enable = true;
  };
}
