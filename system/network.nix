{ ... }:

let
  meta = import ../meta.nix;
in
{
  networking.hostName = meta.hostName;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
}
