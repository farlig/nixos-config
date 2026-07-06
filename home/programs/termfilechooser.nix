{ lib, pkgs, ... }:

# xdg-desktop-portal-termfilechooser wired to yazi in kitty. This is a
# home-manager module (it writes ~/.config and sets session vars), so it now
# lives under home/ instead of modules/ where it originally sat.
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
