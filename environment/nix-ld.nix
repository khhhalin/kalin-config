{ pkgs, ... }:

{
  # Enable nix-ld to run dynamically linked executables
  programs.nix-ld.enable = true;
  
  # Add common libraries needed by precompiled binaries
  programs.nix-ld.libraries = with pkgs; [
    # Standard libraries commonly needed
    stdenv.cc.cc.lib
    zlib
    openssl
    curl
    glibc
    
    # Python/UV related libraries
    libffi
    ncurses
    readline
    sqlite
    bzip2
    xz
    
    # SSL certificates
    cacert
  ];
}
