{ ... }:

# Lean zsh for the headless `bank` server. Deliberately NOT ./zsh.nix — that one
# sources ~/.p10k.zsh (an unmanaged dotfile) and calls fastfetch/bat, which come
# from the desktop-only packages.nix. This keeps the nice-to-haves (autosuggestions,
# syntax highlighting, a clean prompt) with nothing extra dragged onto the server. Prompt is starship: declarative, no config wizard.
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
    };

    shellAliases = {
      grep = "grep --color=auto";
      # eza stands in for ls. No --icons here: they need a Nerd Font, and the
      # font is the SSH client's, not this box's.
      ls = "eza --group-directories-first";
      ll = "eza -lh --git --group-directories-first";
      la = "eza -lah --git --group-directories-first";
      lt = "eza -T -L 2";
      # Rebuild bank from the flake (clone it to ~/nixos-config first, or edit
      # the path). Hostname is fixed to `bank` since this profile is host-specific.
      update = "sudo nixos-rebuild switch --flake ~/nixos-config#bank";
    };

    initContent = ''
      export EDITOR=nvim
      export VISUAL=nvim
    '';
  };

  # Lightweight, no-wizard prompt (replaces the desktop's powerlevel10k).
  programs.starship.enable = true;
}
