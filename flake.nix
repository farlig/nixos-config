{
  description = "Anton's NixOS configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

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

  outputs = { self, nixpkgs, chaotic, ... }@inputs:
    let
      mkHost = hostPath: hostName: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          hostPath
          ./modules/cachix.nix
          ./modules/configuration/common-packages.nix
          ./modules/configuration/quietboot.nix
          ./modules/configuration/users.nix
          ./modules/stylix.nix
          ./modules/configuration/network-share.nix
          chaotic.nixosModules.default

          inputs.stylix.nixosModules.stylix

          inputs.niri.nixosModules.niri
          { programs.niri.enable = true; }

          ./modules/noctalia-greeter.nix

          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit (inputs) lazyvim; inherit hostName inputs; };
            home-manager.users.anton = {
              imports = [ ./home/common.nix ];
            };
          }
        ];
      };
    in {
      nixosConfigurations = {
        antonixos = mkHost ./hosts/antonixos/configuration.nix "antonixos";
        xps13     = mkHost ./hosts/xps13/configuration.nix "xps13";
      };
    };

  nixConfig = {
    extra-substituters = [ 
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };
}
