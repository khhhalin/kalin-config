{ pkgs, ... }:

{
  home.packages = [
    pkgs.thunar
  ];

  # Make Thunar the default handler for folders.
  # (So clicking "Open folder" in apps uses Thunar.)
  xdg.mimeApps.defaultApplications = {
    "inode/directory" = "thunar.desktop";
  };
}
