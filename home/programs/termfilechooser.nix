{ lib, pkgs, ... }:

# xdg-desktop-portal-termfilechooser wired to yazi in kitty. A home-manager
# module: it writes into ~/.config and sets the session vars the portal reads.
{
  xdg.configFile."xdg-desktop-portal-termfilechooser/config" = {
    text = ''
      [filechooser]
      cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
    '';
  };

  home.sessionVariables = {
    TERMCMD = "${lib.getExe pkgs.kitty} -T 'termfilechooser' -e";
  };
}
