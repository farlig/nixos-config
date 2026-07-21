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

      # Maintenance one-shot for bank's Jellyfin: cold-backup the DB and strip
      # duplicate UserData rows, with the stack stopped the whole time. The whole
      # remote script is a quoted heredoc so nothing expands locally — $db and the
      # SQL (backticks and all) reach bank verbatim. An EXIT trap guarantees the
      # stack comes back up even if the backup or SQL step fails.
      uc() {
        ssh anton@bank 'bash -s' <<'REMOTE'
      set -euo pipefail
      cd /home/anton/stacks/jellyfin
      db=/mnt/vault/configs/jellyfin/data/jellyfin.db

      trap 'echo "==> Bringing jellyfin stack back up"; docker compose up -d' EXIT

      echo "==> Bringing jellyfin stack down"
      docker compose down

      echo "==> Backing up database (overwriting previous backup)"
      cp -f "$db" "$db.backup"

      echo "==> Running dedupe SQL against UserData"
      sqlite3 "$db" <<'SQL'
      delete from `UserData`
      where CustomDataKey IN (
        select CustomDataKey
        from `UserData`
        group by UserId, CustomDataKey
        having count(*) > 1
      );
      SQL

      echo "==> Dedupe complete"
      REMOTE
      }
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
