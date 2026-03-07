{ pkgs, lib, ... }:

let
  distroHelperScript = builtins.readFile ./scripts/debbox.sh;

  distroBin = name: pkgs.writeShellScriptBin name distroHelperScript;

  debianBin = distroBin "debian";
  ubuntuBin = distroBin "ubuntu";
  fedoraBin = distroBin "fedora";
  archBin   = distroBin "arch";

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
  # Common /etc/containers config (registries, policy, etc.)
  virtualisation.containers.enable = true;

  # Rootless Podman is the best match for the BlendOS-style workflow.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Needed for rootless containers on hardened systems.
  security.unprivilegedUsernsClone = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    podman
    distrobox
    debianBin
    ubuntuBin
    fedoraBin
    archBin
    debDesktop
  ];

  # System-wide file association for .deb double-clicks (no Home Manager needed).
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
