{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    noctalia = {
      url = "github:noctalia-dev/noctalia";
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
 
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.antonixos = nixpkgs.lib.nixosSystem {
      modules = [ 
        ./configuration.nix
        inputs.niri.nixosModules.niri
        {
          programs.niri.enable = true;
        }
        ./noctalia.nix
        inputs.home-manager.nixosModules.home-manager
        {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "backup";

            home-manager.extraSpecialArgs = { inherit (inputs) lazyvim; };
            home-manager.users.anton = {
            imports = [ ./home.nix ];
          };
        }
      ];
      specialArgs = { inherit inputs; };
    };
  };

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };
}
