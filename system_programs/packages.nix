{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    ly
    xwayland-satellite
    python3
    gnumake
    bison
    gcc
    binutils
    file
    flex
    rsync
  ];
}
