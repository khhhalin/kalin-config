{ lib, ... }:

{
  # Official notes:
  # - NixOS wiki: https://wiki.nixos.org/wiki/Keyd
  # - Upstream docs: https://raw.githubusercontent.com/rvaiya/keyd/master/docs/keyd.scdoc

  services.keyd = {
    enable = true;

    keyboards.default = {
      ids = [ "*" ];

      settings = {
        main = {
          # Best-practice approach (avoids keyd running commands as root):
          # - Tap Left Super -> emits Meta+Space
          # - Hold Left Super -> behaves as normal Meta/Super
          # Pair this with a compositor bind for Mod+Space.
          leftmeta = "overload(meta, macro(M-space))";
        };
      };

      # Put raw keyd config here if you ever want to paste upstream examples.
      extraConfig = "";
    };
  };

  # Wayland/libinput quirk: treat keyd virtual keyboard as internal.
  # Prevents touchpad 'disable-while-typing' weirdness on some laptops.
  # (From NixOS wiki + upstream FAQ)
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Serial Keyboards]

    MatchUdevType=keyboard
    MatchName=keyd*keyboard
    AttrKeyboardIntegration=internal
  '';

  # Some setups log "failed to set effective group to 'keyd'" unless the group exists.
  users.groups.keyd = {};

  # NixOS' default keyd unit hardens with `RestrictSUIDSGID=true`, but keyd
  # attempts a `setgid()` at startup. This results in `setgid: Operation not permitted`
  # and the service fails to start.
  systemd.services.keyd.serviceConfig.RestrictSUIDSGID = lib.mkForce false;

  # The generated unit also constrains capabilities. keyd needs `CAP_SETGID`
  # for its privilege-drop step; without it, startup fails.
  systemd.services.keyd.serviceConfig.CapabilityBoundingSet = lib.mkForce [
    "CAP_SYS_NICE"
    "CAP_IPC_LOCK"
    "CAP_SETGID"
  ];
}
