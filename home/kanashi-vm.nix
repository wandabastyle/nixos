{
  config,
  lib,
  pkgs,
  inputs,
  unstablePkgs,
  ...
}:

{
  home.username = "kanashi";
  home.homeDirectory = "/home/kanashi";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  imports = [
    ./modules/base.nix
    ./modules/dotfiles.nix
    ./modules/noctalia.nix
    ./modules/niri-vm.nix
  ];
}
