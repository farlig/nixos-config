{config, pkgs, ...}:

{
  programs.yazi = {
      enable = true;

      plugins = {
          clipboard = pkgs.yaziPlugins.clipboard;
      };

      initLua = ''
        require("clipboard")
      '';

      settings = {
          manager = {
              show_hidden = true;
          };
      };
  };
}
