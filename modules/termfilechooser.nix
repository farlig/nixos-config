{
  lib,
  pkgs,
  ...
}: 

{
  xdg = {
    configFile."xdg-desktop-portal-termfilechooser/config" = {
      text = ''
        [filechooser]
        cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
      '';
    };
  };
  home.sessionVariables = {
    TERMCMD = "${lib.getExe pkgs.kitty} -T 'termfilechooser' -e";
  };
}

