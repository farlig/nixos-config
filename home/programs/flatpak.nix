{ ... }:

# Shared nix-flatpak policy for the hosts that have Flatpaks. Imported next to
# inputs.nix-flatpak.homeManagerModules.nix-flatpak in home/default.nix — the
# options below only exist where that module is loaded, so this file cannot go
# in the unconditional import list.
{
  # Flathub content is not tracked by flake.lock, so a lockfile bump never moves
  # a Flatpak. Upgrade the declared apps on every rebuild instead (nix-flatpak
  # appends --or-update to its install commands). Apps pinned to a commit hash
  # are exempt; we pin none.
  services.flatpak.update.onActivation = true;
}
