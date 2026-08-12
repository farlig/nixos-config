{ inputs, ... }:

# comma (`,`) — run a program without installing it: `, cowsay hi` fetches
# cowsay for that one invocation. Backed by the nix-index-database flake's
# prebuilt, weekly-updated database (nixos-unstable), so it works out of the
# box with no local `nix-index` run. The flake's HM module is imported in
# home/default.nix; this file just turns comma on.
{
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  programs.nix-index-database.comma.enable = true;
}
