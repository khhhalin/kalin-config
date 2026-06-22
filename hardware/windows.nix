{ pkgs, lib, options, config, ... }:

let
  meta = import ../configuration/meta.nix;
  hasGraphics32 = lib.hasAttrByPath [ "hardware" "graphics" "enable32Bit" ] options;
  hasOpenGL32 = lib.hasAttrByPath [ "hardware" "opengl" "driSupport32Bit" ] options;
in
{
  # Wine needs 32-bit OpenGL/Vulkan userspace on most systems.
  # NixOS renamed these options across releases; prefer the new name.
  config = lib.mkMerge [
    (lib.mkIf hasGraphics32 {
      hardware.graphics.enable32Bit = true;
    })

    (lib.mkIf (hasOpenGL32 && !hasGraphics32) {
      hardware.opengl.driSupport32Bit = true;
    })

    {
      environment.systemPackages = with pkgs; [
        # GUI manager for Wine prefixes + installers.
        bottles

        # Wine runtime + helper tools.
        wineWowPackages.staging
        winetricks

        # Common installer helpers.
        cabextract
        p7zip
      ];
    }

    (lib.mkIf meta.enableLookingGlass {
      environment.systemPackages = with pkgs; [
        looking-glass-client
      ];

      # KVMFR kernel module for Looking Glass shared memory.
      boot.extraModulePackages = [ config.boot.kernelPackages.kvmfr ];
      boot.initrd.kernelModules = [ "kvmfr" ];
      # Adjust to your display resolution: width * height * 4 / 1024 / 1024 + 10
      # 64 MB covers 1080p/1440p; use 128 MB for 4K.
      boot.kernelParams = [ "kvmfr.static_size_mb=64" ];

      # Udev rules for the kvmfr device node.
      services.udev.packages = lib.singleton (pkgs.writeTextFile {
        name = "kvmfr";
        text = ''
          SUBSYSTEM=="kvmfr", GROUP="kvm", MODE="0660", TAG+="uaccess"
        '';
        destination = "/etc/udev/rules.d/70-kvmfr.rules";
      });

      # Libvirtd and cgroup device ACL so the VM can access /dev/kvmfr0.
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          verbatimConfig = ''
            namespaces = []
            cgroup_device_acl = [
              "/dev/null", "/dev/full", "/dev/zero",
              "/dev/random", "/dev/urandom",
              "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
              "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
              "/dev/kvmfr0"
            ]
          '';
        };
      };
    })
  ];
}
