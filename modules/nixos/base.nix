{ ... }:

# The host-agnostic foundation: things every machine wants regardless of whether
# it has a graphical session. The desktop/laptop bundle (./default.nix) imports
# this and layers the GUI stack on top; a headless server imports base.nix
# directly and skips the desktop modules.
{
  imports = [
    ./nix.nix
    ./locale.nix
    ./networking.nix
    ./boot.nix
    ./users.nix
    ./caches.nix
  ];

  # NixOS release the shared defaults were written against. Host-agnostic.
  system.stateVersion = "26.05";
}
