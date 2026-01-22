{ pkgs, ... }:

{
  # Cursor theme: controls pointer shapes (including resize cursors) and size.
  # This is the simplest reliable way to get proper resize/hover cursors across Wayland apps.
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;

    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 20;
  };
}
