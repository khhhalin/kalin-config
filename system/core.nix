{ ... }:

let
  meta = import ../configuration/meta.nix;
in
{
  time.timeZone = meta.timeZone;
  services.timesyncd.enable = true;

  services.openssh = {
    enable = true;
    openFirewall = false;
  };
}
