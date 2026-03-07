{ ... }:

{
  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    application/vnd.debian.binary-package=debian-deb-install.desktop
    application/x-debian-package=debian-deb-install.desktop
    application/x-deb=debian-deb-install.desktop

    [Added Associations]
    application/vnd.debian.binary-package=debian-deb-install.desktop
    application/x-debian-package=debian-deb-install.desktop
    application/x-deb=debian-deb-install.desktop
  '';
}
