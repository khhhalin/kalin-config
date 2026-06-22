{ lib, ... }:

let
  meta = import ../configuration/meta.nix;
in
{
  hardware.bluetooth = {
    enable = meta.enableBluetooth;
    powerOnBoot = lib.mkDefault meta.enableBluetooth;
  };
  services.blueman.enable = meta.enableBluetooth;
}
