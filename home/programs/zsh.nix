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
      # Deploy the headless `bank` server from here: build the closure locally,
      # copy it over Tailscale, activate with remote sudo. Works from any desktop
      # host (antonixos/xps13) whose anton key is authorized on bank.
      bupdate = "nixos-rebuild switch --flake ~/nixos-config#bank --target-host anton@bank --use-remote-sudo";
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
