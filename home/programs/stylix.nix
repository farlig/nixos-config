{ ... }:

# Per-application opt-outs from Stylix theming (these apps are themed by
# noctalia / their own config instead).
{
  stylix.targets.niri.enable = false;
  stylix.targets.kitty.enable = false;
  stylix.targets.noctalia.enable = false;
  # noctalia's yazi theme template rewrites ~/.config/yazi/theme.toml at
  # runtime; when stylix also manages that file, home-manager activation
  # trips over the runtime copy / stale .backup on every later rebuild.
  stylix.targets.yazi.enable = false;
}
