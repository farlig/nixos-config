{config, pkgs, ...}:

{
  programs.yazi = {
      enable = true;
      shellWrapperName = "y";

      plugins = {
        clipboard = pkgs.yaziPlugins.clipboard;
      };

      settings = {
        manager = {
          show_hidden = true;
        };
      };

      keymap = {
        mgr.prepend_keymap = [
          { on = ["y"]; run = [ "yank" "plugin clipboard -- --action=copy" ]; }
          { on = ["<C-p>"]; run = "plugin clipboard --action=paste"; }
        ];
      };
  };
}
