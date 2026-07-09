{config, pkgs, ...}:

{
  programs.yazi = {
      enable = true;
      shellWrapperName = "y";

      plugins = {
        clipboard = pkgs.yaziPlugins.clipboard;
      };

      settings = {
        mgr = {
          show_hidden = true;
          # Show file size + last-modified time on each row (see initLua below,
          # which defines the "size_and_mtime" linemode this refers to).
          linemode = "size_and_mtime";
        };
      };

      # Custom linemode combining readable size and mtime. Yazi's built-in
      # linemodes only show one attribute at a time; this is the upstream
      # recommended snippet (yazi-rs.github.io → configuration/yazi, "linemode").
      initLua = ''
        function Linemode:size_and_mtime()
          local time = math.floor(self._file.cha.mtime or 0)
          if time == 0 then
            time = ""
          elseif os.date("%Y", time) == os.date("%Y") then
            time = os.date("%b %d %H:%M", time)
          else
            time = os.date("%b %d  %Y", time)
          end
          local size = self._file:size()
          return string.format("%s %s", size and ya.readable_size(size) or "-", time)
        end
      '';

      keymap = {
        mgr.prepend_keymap = [
          { on = ["y"]; run = [ "yank" "plugin clipboard -- --action=copy" ]; }
          { on = ["<C-p>"]; run = "plugin clipboard --action=paste"; }
        ];
      };
  };
}
