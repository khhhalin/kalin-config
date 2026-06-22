{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, zlib
, openssl
, libffi
, ncurses
, readline
, sqlite
, glibc
, gcc-unwrapped
}:

stdenv.mkDerivation rec {
  pname = "kimi-cli";
  version = "0.2.0"; # Update this to the actual version

  # You'll need to download the binary or build from source
  # This is a template - you'll need to adjust based on how kimi-cli is distributed
  src = fetchurl {
    url = "https://github.com/your-repo/kimi-cli/releases/download/v${version}/kimi-cli-linux-x64";
    sha256 = lib.fakeSha256; # Replace with actual hash
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    openssl
    libffi
    ncurses
    readline
    sqlite
    glibc
    gcc-unwrapped.lib
  ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin
    cp $src $out/bin/kimi
    chmod +x $out/bin/kimi
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Kimi CLI - AI assistant command line interface";
    homepage = "https://github.com/your-repo/kimi-cli";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "kimi";
  };
}
