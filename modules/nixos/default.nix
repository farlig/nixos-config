{ inputs, ... }:

# Everything that is identical across every host lives here. A host imports
# this once (see hosts/<name>/default.nix) and then only declares what makes
# that machine unique.
{
  imports = [
    # Local shared modules
    ./nix.nix
    ./locale.nix
    ./networking.nix
    ./boot.nix
    ./audio.nix
    ./desktop.nix
    ./packages.nix
    ./users.nix
    ./network-share.nix
    ./stylix.nix
    ./caches.nix
    ./home-manager.nix

    # External flake modules, wired in one place instead of per-host
    inputs.chaotic.nixosModules.default
    inputs.stylix.nixosModules.stylix
    inputs.niri.nixosModules.niri
    inputs.noctalia-greeter.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];

  # NixOS release the shared defaults were written against. Host-agnostic.
  system.stateVersion = "26.05";
}
