{ pkgs, ... }:

# System-wide theming via Stylix. Per-target opt-outs on the home side live in
# home/programs/stylix.nix.
{
  stylix = {
    enable = true;
    autoEnable = true;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  };
}
