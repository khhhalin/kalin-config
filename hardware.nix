# Audio, bluetooth, firmware/removable media, and Wine support.
{ pkgs, lib, options, meta, ... }:

let
  hasGraphics32 = lib.hasAttrByPath [ "hardware" "graphics" "enable32Bit" ] options;
  hasOpenGL32 = lib.hasAttrByPath [ "hardware" "opengl" "driSupport32Bit" ] options;
in
{
  config = lib.mkMerge [
    # ── Audio (PipeWire) ────────────────────────────────────────────
    {
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        wireplumber.enable = true;
      };
    }

    # ── Bluetooth ───────────────────────────────────────────────────
    {
      hardware.bluetooth.enable = meta.enableBluetooth;
      hardware.bluetooth.powerOnBoot = lib.mkDefault meta.enableBluetooth;
      services.blueman.enable = meta.enableBluetooth;
    }

    # ── Firmware updates + removable media ──────────────────────────
    {
      services.fwupd.enable = true;
      services.udisks2.enable = true;
    }

    # ── Wine / Windows apps ─────────────────────────────────────────
    # Needs 32-bit GL userspace; the option was renamed across releases.
    (lib.mkIf hasGraphics32 { hardware.graphics.enable32Bit = true; })
    (lib.mkIf (hasOpenGL32 && !hasGraphics32) { hardware.opengl.driSupport32Bit = true; })
    {
      environment.systemPackages = with pkgs; [
        bottles wineWowPackages.staging winetricks cabextract p7zip
      ];
    }
  ];
}
