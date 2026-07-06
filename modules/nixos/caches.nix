{ ... }:

# Binary caches — the single source of truth for all substituters. Replaces the
# auto-importing modules/cachix.nix + modules/cachix/ folder (no more `cachix use`
# clobber) and also absorbs the noctalia cache that used to live in flake.nix
# `nixConfig`, so every cache is declared in one place.
#
# Note: flake `nixConfig` and NixOS `nix.settings` are not identical. `nixConfig`
# applies (with a trust prompt) while evaluating/building the flake itself, which
# helps a *first* build on a fresh machine pull from these caches before the
# system's nix.conf exists. `nix.settings` here writes the built system's
# nix.conf, used for every rebuild afterwards. On these already-provisioned hosts
# that distinction doesn't matter; if you ever bootstrap a brand-new machine and
# want noctalia cached on the very first build, temporarily re-add it to
# flake.nix `nixConfig`.
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };
}
