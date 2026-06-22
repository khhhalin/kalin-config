{ ... }:

{
  services.upower.enable = true;

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
}
