{ ... }:

{
  programs.zsh = {
    enable = true;

    shellAliases = {
      # NixOS rebuild for this machine.
      rebuild = "sudo nixos-rebuild switch --flake /home/kalin/home-config#KalinBook";
      rewrite = "code ~/home-config";
    };
  };
}
