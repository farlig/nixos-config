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
      update = "sudo nixos-rebuild switch --flake ~/nixos-config#$HOST";
    };

    initContent = ''
      source ~/.p10k.zsh
      eval "fastfetch"
      export EDITOR=nvim
      export VISUAL=nvim
    '';

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [ "tailscale" ];
    };
  };
}
