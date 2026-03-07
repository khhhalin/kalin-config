{ pkgs, ... }:

let
  distroHelperScript = builtins.readFile ../scripts/debbox.sh;

  distroBin = name: pkgs.writeShellScriptBin name distroHelperScript;

  debianBin = distroBin "debian";
  ubuntuBin = distroBin "ubuntu";
  fedoraBin = distroBin "fedora";
  archBin = distroBin "arch";

  debDesktop = pkgs.makeDesktopItem {
    name = "debian-deb-install";
    desktopName = "Install DEB (Debian container)";
    comment = "Install a .deb into a Debian container (Podman/Distrobox)";
    exec = "foot -e debian install %f";
    terminal = false;
    categories = [ "System" "Utility" ];
    mimeTypes = [
      "application/vnd.debian.binary-package"
      "application/x-debian-package"
      "application/x-deb"
    ];
  };

in
{
  environment.systemPackages = with pkgs; [
    podman
    distrobox
    debianBin
    ubuntuBin
    fedoraBin
    archBin
    debDesktop
  ];
}
