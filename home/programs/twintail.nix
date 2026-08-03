{ ... }:

# Twintail Launcher — a multi-platform launcher for anime-styled games (mod
# support, downloads, QoL for Genshin/Star Rail/etc). Not packaged in nixpkgs,
# so it comes from Flathub via nix-flatpak. antonixos (gaming desktop) only; it
# needs services.flatpak.enable at the system level (hosts/antonixos/default.nix)
# and the nix-flatpak HM module (imported for antonixos in home/default.nix).
# nix-flatpak wires up the flathub remote itself, so just naming the app is enough.
{
  services.flatpak.packages = [ "app.twintaillauncher.ttl" ];
}
