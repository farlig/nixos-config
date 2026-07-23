{
  description = "Anton's NixOS configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # Declarative Flatpak (used on xps13 for the Bitwarden flatpak, whose
    # biometric unlock works where the nixpkgs build hits bitwarden/clients#15790).
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lazyvim = {
      url = "github:pfassina/lazyvim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      # A host is just its own folder under ./hosts. Everything shared lives in
      # ./modules/nixos (imported once, from the host module).
      mkHost = hostName: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs hostName; };
        modules = [ ./hosts/${hostName} ];
      };
    in {
      nixosConfigurations = {
        antonixos = mkHost "antonixos";
        xps13     = mkHost "xps13";
        bank      = mkHost "bank";
      };
    };

  # All binary caches (including noctalia, previously here in `nixConfig`) are now
  # declared once in modules/nixos/caches.nix. See the note there before adding a
  # cache back here for first-build bootstrapping on a fresh machine.
}
