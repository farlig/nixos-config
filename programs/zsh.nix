{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      grep = "grep --color=auto";
      ls = "lsd";
      cat = "bat";
    };

    initContent = ''
      eval "fastfetch"
      export EDITOR=nvim
      export VISUAL=nvim
      function y() {
	      local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	      command yazi "$@" --cwd-file="$tmp"
	      IFS= read -r -d \'\' cwd < "$tmp"
	      [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	      command rm -f -- "$tmp"
      }
    '';

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
  };
}
