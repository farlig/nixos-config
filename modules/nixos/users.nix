{ pkgs, ... }:

# The primary user account. Shared across hosts.
{
  users.users.anton = {
    isNormalUser = true;
    description = "Anton";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };
}
