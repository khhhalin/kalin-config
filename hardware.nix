# Audio, bluetooth, firmware/removable media, and Wine support.
{ pkgs, lib, meta, ... }:

{
  # ── Audio (PipeWire) ────────────────────────────────────────────
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;
  };

  # ── Bluetooth ───────────────────────────────────────────────────
  hardware.bluetooth.enable = meta.enableBluetooth;
  hardware.bluetooth.powerOnBoot = lib.mkDefault meta.enableBluetooth;
  services.blueman.enable = meta.enableBluetooth;

  # ── Firmware updates + removable media ──────────────────────────
  services.fwupd.enable = true;
  services.udisks2.enable = true;

  # ── VA-API hw video decode (Ivybridge needs the legacy i965 driver) ──
  hardware.graphics.extraPackages = with pkgs; [ intel-vaapi-driver ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "i965";

  # ── Wine / Windows apps (needs 32-bit GL userspace) ─────────────
  hardware.graphics.enable32Bit = true;
  environment.systemPackages = with pkgs; [
    wineWowPackages.staging winetricks cabextract p7zip
  ];
}
