{ ... }:

# Sober — Roblox player runner for Linux (the vinegarhq successor to Vinegar's
# player support; Vinegar itself is now Studio-only). Not packaged in nixpkgs,
# so it comes from Flathub via nix-flatpak. antonixos (gaming desktop) only; it
# needs services.flatpak.enable at the system level (hosts/antonixos/default.nix)
# and the nix-flatpak HM module (imported for antonixos in home/default.nix).
# nix-flatpak wires up the flathub remote itself, so just naming the app is enough.
{
  services.flatpak.packages = [ "org.vinegarhq.Sober" ];
}
