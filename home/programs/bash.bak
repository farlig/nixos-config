{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      grep = "grep --color=auto";
      ls = "lsd";
      cat = "bat";
    };

    initExtra = ''
    eval "fastfetch"
    export EDITOR=nvim
    export VISUAL=nvim
    export PS1='\[\e[38;5;76m\]\u\[\e[0m\] in \[\e[38;5;32m\]\w\[\e[0m\] \\$ '
    '';
  };
}
