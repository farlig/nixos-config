{ ... }:

# Nix daemon settings and nixpkgs-wide policy shared by all hosts.
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@wheel" ];
  };

  # GitHub token for `github:` fetches, kept out of the store; lifts the
  # 60 req/hour anonymous API limit. `!include` no-ops when the file is absent.
  nix.extraOptions = ''
    !include /etc/nix/access-tokens.conf
  '';

  # Keep the store from growing unbounded: collect old generations weekly and
  # deduplicate identical files. Bootloader generation limits (which keep the
  # ESP from filling) are set per-host alongside the bootloader.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-39.8.10"
    ];
  };
}
