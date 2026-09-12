{ lib, ... }:

# Vicinae launcher. The daemon runs as a user service under the graphical
# session so the window opens instantly; Mod+D toggles it from niri
# (see home/programs/niri/config-<host>.kdl).
#
# Colours and font come from stylix's vicinae target, which writes them
# through these same options — nothing to opt out of here.
{
  programs.vicinae = {
    enable = true;
    systemd.enable = true;

    # Calculator backend. The default, numen, hands
    # `QLocale::system().name()` to `std::locale`; that name carries no
    # codeset ("en_DK"), and glibc only knows "en_DK.UTF-8", so it throws and
    # every calculation fails with no result row. Qalculate takes its locale
    # from the environment instead.
    settings.providers.calculator.preferences.backend = "qalculate";

    # A translucent launcher window. Vicinae's `material` (blur by default)
    # only shows through at opacity < 1, and it asks niri to blur behind the
    # window over ext-background-effect, so no niri layer-rule is involved.
    # mkForce because stylix's vicinae target drives this from the global
    # stylix.opacity.popups, which every other popup would follow too.
    settings.launcher_window.opacity = lib.mkForce 0.9;
  };
}
