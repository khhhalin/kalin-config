{ ... }:

let
  meta = import ../meta.nix;
in
{
  time.timeZone = meta.timeZone;
  services.timesyncd.enable = true;
}
