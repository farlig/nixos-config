{ config, pkgs, lazyvim, hostName, ... }:

# Anton's home-manager configuration (was home/common.nix). Imported by the
# system build via modules/nixos/home-manager.nix.
{
  imports = [
    ./programs/niri/niri.nix
    ./programs/nvim.nix
    ./programs/zsh.nix
    ./programs/kitty.nix
    ./programs/yazi.nix
    ./programs/fastfetch.nix
    ./programs/bitwarden.nix
    ./programs/noctalia.nix
    ./programs/stylix.nix
    ./programs/termfilechooser.nix
    lazyvim.homeManagerModules.default
  ];

  home.username = "anton";
  home.homeDirectory = "/home/anton";
  home.stateVersion = "26.05";

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    download = "${config.home.homeDirectory}/downloads";
    videos = "${config.home.homeDirectory}/videos";
    pictures = "${config.home.homeDirectory}/pictures";
    documents = "${config.home.homeDirectory}/documents";
    projects = "${config.home.homeDirectory}/projects";
  };
}
