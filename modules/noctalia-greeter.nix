{ inputs, pkgs, ... }:

{
  imports = [inputs.noctalia-greeter.nixosModules.default];

  programs.noctalia-greeter = {
    enable = true;
    package = inputs.noctalia-greeter.packages.${pkgs.system}.default;

    greeter-args = "--session niri-session";
  };
}
