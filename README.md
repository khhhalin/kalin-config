# kalin-config

Minimal NixOS configuration.

## Dotfiles

Home Manager is not used here. Manage dotfiles separately (chezmoi/stow/yadm/bare-git, etc.).

## Rebuild

sudo nixos-rebuild switch --flake .#KalinBook

## Customize

- meta.nix: adjust hostName, userName, locale, keyboard, etc.
