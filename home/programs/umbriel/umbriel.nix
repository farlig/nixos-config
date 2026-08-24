{ inputs, ... }:

# Umbriel, installed alongside niri as a second selectable session. The system
# side (session registration, portal) is in modules/nixos/desktop.nix.
#
# Like the niri config, config-antonixos.toml is raw, hand-edited config rather
# than a Nix attrset — it is the whole configuration, and the module takes a
# path directly. `validateConfig` (on by default) runs `umbriel validate -c`
# during the build, so a bad chord or unknown action breaks the rebuild instead
# of the session.
{
  imports = [ inputs.umbriel.homeModules.default ];

  programs.umbriel = {
    enable = true;
    settings = ./config-antonixos.toml;
  };
}
