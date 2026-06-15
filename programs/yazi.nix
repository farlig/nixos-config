{config, pkgs, ...}:

{
  programs.yazi = {
      enable = true;

      plugins = {
          clipboard = pkgs.yaziPlugins.clipboard;
      };

      initLua = ''
        require("clipboard"):setup()
      '';

      settings = {
          manager = {
              show_hidden = true;
          };
      };
  };
}
