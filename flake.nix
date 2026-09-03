{
  description = "Anton's NixOS configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # Declarative Flatpak management. Used for the apps that are only shipped
    # as Flatpaks (Bitwarden on xps13, the Flathub-only launchers on antonixos).
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # Prebuilt, weekly-updated nix-index database (nixos-unstable). Backs comma
    # (`,`) so it can run programs without installing them, with no local
    # `nix-index` run needed. Home-manager module in home/programs/comma.nix.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Helium browser, which nixpkgs does not package. This flake unpacks
    # upstream's prebuilt .deb the way nixpkgs packages Vivaldi/Brave; the
    # version it ships trails upstream, so check it when updating.
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
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

  # Binary caches are declared in modules/nixos/caches.nix, not in a `nixConfig`
  # block here. See the note in that file before adding one back for first-build
  # bootstrapping on a fresh machine.
}
