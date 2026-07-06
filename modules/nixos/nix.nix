{ ... }:

# Nix daemon settings and nixpkgs-wide policy shared by all hosts.
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@wheel" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-39.8.10"
    ];
  };
}
