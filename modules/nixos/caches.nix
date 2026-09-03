{ ... }:

# Binary caches — the single source of truth for all substituters. Every cache
# the hosts use is declared here, including the ones a flake input would
# otherwise ask for in its own `nixConfig`.
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
