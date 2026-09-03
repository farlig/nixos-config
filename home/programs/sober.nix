{ ... }:

# Sober — Roblox player runner for Linux (the vinegarhq successor to Vinegar's
# player support; Vinegar itself is now Studio-only). Not packaged in nixpkgs,
# so it comes from Flathub via nix-flatpak. antonixos (gaming desktop) only; it
# needs services.flatpak.enable at the system level (hosts/antonixos/default.nix)
# and the nix-flatpak HM module (imported for antonixos in home/default.nix).
# nix-flatpak wires up the flathub remote itself, so just naming the app is enough.
{
  services.flatpak.packages = [ "org.vinegarhq.Sober" ];

  # Text-input-in-niri fix. Sober is SDL3-based; under niri its native-Wayland
  # (Vulkan) path swallows keystrokes in chat/text boxes while WASD and game
  # shortcuts still work — an nvidia + niri combination (niri#2682, sober#1771).
  # Two known fixes:
  #   1. Switch the Roblox renderer from Vulkan to OpenGL — stays on native
  #      Wayland, so mouse-look/shift-lock keep working. This is the one in use;
  #      it's `"use_opengl": true` in Sober's own config, which is app runtime
  #      state inside the Flatpak's data dir and not managed here.
  #   2. Force XWayland (`--socket=x11 --nosocket=wayland`; needs
  #      xwayland-satellite, which niri runs). Also fixes typing but breaks
  #      mouse-look in games that force FPS/shift-lock. If OpenGL ever regresses,
  #      switch to this instead:
  #        services.flatpak.overrides.settings."org.vinegarhq.Sober".Context.sockets = [ "x11" "!wayland" ];
}
