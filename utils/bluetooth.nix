{ ... }:

let
  meta = import ../meta.nix;
in
{
  hardware.bluetooth.enable = meta.enableBluetooth;
  services.blueman.enable = meta.enableBluetooth;
}
