{ ... }:

{
  boot.loader.systemd-boot = {
    enable = true;
    # Keep the EFI partition from filling up with old generations.
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;
}
