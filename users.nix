{ pkgs, meta, ... }:

{
  users.users.${meta.userName} = {
    isNormalUser = true;
    description = meta.fullName;
    extraGroups = [ "wheel" "networkmanager" "input" "uinput" "video" "tty" ];
    shell = pkgs.zsh;

    # Required for rootless Podman user namespaces.
    subUidRanges = [ { startUid = 100000; count = 65536; } ];
    subGidRanges = [ { startGid = 100000; count = 65536; } ];
  };
}
