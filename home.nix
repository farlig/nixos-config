{ config, pkgs, lazyvim, ... }:

{
  imports = [
    ./programs/niri/niri.nix
    ./programs/nvim.nix
    ./programs/bash.nix
    ./programs/kitty.nix
    lazyvim.homeManagerModules.default
  ];
  
  home.username = "anton";
  home.homeDirectory = "/home/anton";
  home.stateVersion = "26.05";
  programs.yazi.enable = true;
}
