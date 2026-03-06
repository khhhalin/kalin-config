{ pkgs, lib, ... }:

let
  debbox = pkgs.writeShellScriptBin "debbox" (builtins.readFile ./scripts/debbox.sh);

  debboxFor = distro: pkgs.writeShellScriptBin ("debbox-" + distro) ''
    exec debbox --distro ${distro} "$@"
  '';

  debboxDebian = debboxFor "debian";
  debboxUbuntu = debboxFor "ubuntu";
  debboxFedora = debboxFor "fedora";
  debboxArch   = debboxFor "arch";

  debboxDesktop = pkgs.makeDesktopItem {
    name = "debbox-open";
    desktopName = "Install DEB (Container)";
    comment = "Install a .deb into a Debian container (Podman/Distrobox)";
    exec = "foot -e debbox %f";
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
    debbox
    debboxDebian
    debboxUbuntu
    debboxFedora
    debboxArch
    debboxDesktop
  ];

  # System-wide file association for .deb double-clicks (no Home Manager needed).
  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    application/vnd.debian.binary-package=debbox-open.desktop
    application/x-debian-package=debbox-open.desktop
    application/x-deb=debbox-open.desktop

    [Added Associations]
    application/vnd.debian.binary-package=debbox-open.desktop
    application/x-debian-package=debbox-open.desktop
    application/x-deb=debbox-open.desktop
  '';
}
