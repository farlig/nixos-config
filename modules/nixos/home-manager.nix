{ inputs, hostName, ... }:

# Wires home-manager into the system build and points Anton's user at the
# home configuration in ../../home. hostName is threaded through so home
# modules (e.g. the niri config picker) can branch on the machine.
{
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit (inputs) lazyvim; inherit hostName inputs; };
    users.anton = {
      imports = [ ../../home ];
    };
  };
}
