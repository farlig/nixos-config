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

  # anton's login shell — enabled here next to the shell assignment so every
  # host that has the user also has a working zsh login shell.
  programs.zsh.enable = true;
}
