{ pkgs, ... }:

{
  # Common system utilities installed on every machine
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    gnupg
    unzip
    rsync
    openssh
    jq
    ripgrep
    fd
  ];
}
