{ inputs, ... }:

# The full desktop/laptop bundle: base.nix (host-agnostic foundation) plus the
# graphical session, theming, GUI packages and home-manager. Desktop hosts
# (antonixos, xps13) import this. A headless server imports ./base.nix directly
# and layers its own server modules instead — see hosts/bank.
{
  imports = [
    # Host-agnostic foundation (nix, locale, networking, boot, users, caches).
    ./base.nix

    # Desktop-only local modules
    ./audio.nix
    ./desktop.nix
    ./packages.nix
    ./network-share.nix
    ./stylix.nix
    ./home-manager.nix

    # External flake modules, wired in one place instead of per-host
    inputs.chaotic.nixosModules.default
    inputs.stylix.nixosModules.stylix
    inputs.niri.nixosModules.niri
    inputs.noctalia-greeter.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];
}
