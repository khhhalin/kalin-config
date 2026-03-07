{ lib, ... }:

{
  virtualisation.containers.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  security.unprivilegedUsernsClone = lib.mkDefault true;
}
