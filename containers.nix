# Podman + distrobox, with distro helper scripts and a .deb file handler.
{ pkgs, lib, ... }:

let
  distroHelperScript = builtins.readFile ./scripts/distrobox.sh;
  distroBin = name: pkgs.writeShellScriptBin name distroHelperScript;

  # `pkgs` — browse installed packages by system (host + containers) in fzf.
  pkgsBin = pkgs.writeShellScriptBin "pkgs" (builtins.readFile ./scripts/pkgs.sh);

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
  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  security.unprivilegedUsernsClone = lib.mkDefault true;

  environment.systemPackages = [
    pkgs.podman
    pkgs.distrobox
    (distroBin "debian")
    (distroBin "ubuntu")
    (distroBin "fedora")
    (distroBin "arch")
    debDesktop
    pkgsBin
  ];

  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    application/vnd.debian.binary-package=debian-deb-install.desktop
    application/x-debian-package=debian-deb-install.desktop
    application/x-deb=debian-deb-install.desktop

    [Added Associations]
    application/vnd.debian.binary-package=debian-deb-install.desktop
    application/x-debian-package=debian-deb-install.desktop
    application/x-deb=debian-deb-install.desktop
  '';
}
