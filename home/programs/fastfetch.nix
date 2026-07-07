{ config, ... }:

# Declarative fastfetch config. Based on the "hypr" preset by Bina:
# https://github.com/LierB/fastfetch/blob/master/presets/hypr.jsonc
# Logo points at Anton's profile picture; packages label fixed for NixOS.
#
# Icons are written as \uXXXX escapes rather than raw Nerd Font glyphs: the
# glyphs live in the Private Use Area and get silently stripped when this file
# is edited, which is why the icons kept vanishing. These are the exact
# JetBrainsMono Nerd Font codepoints from the upstream preset.
{
  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
        "logo": {
            // Absolute path: fastfetch does NOT expand "~" in the source.
            // Points at a pre-downscaled 272x340 copy of "frieren chibi-.png":
            // kitty-direct displays the PNG at its native pixel resolution and
            // ignores the "height" option, so the on-screen size is controlled
            // by the image dimensions. Regenerate with:
            //   magick "frieren chibi-.png" -resize x340 "frieren chibi-fastfetch.png"
            "source": "${config.home.homeDirectory}/pictures/pfps/Frieren/frieren chibi-fastfetch.png",
            // "kitty-direct" hands the PNG straight to kitty for decoding.
            // The plain "kitty" type re-encodes the image and needs image
            // libraries that nixpkgs' fastfetch is not built with (would
            // silently fall back to the ASCII logo otherwise).
            "type": "kitty-direct",
            // kitty-direct draws the PNG at native size and does NOT resize to
            // these, but fastfetch still uses width/height to reserve the logo
            // area and place the info text to its right. Set them to the image's
            // actual cell footprint (~272x340px ~= 32 cols x 18 rows) so the text
            // starts right at the image edge. Nudge "width" down for more text
            // room, up if the text overlaps the image.
            "width": 32,
            "height": 18,
            "padding": {
                "top": 2
            }
        },
        "display": {
            "separator": " "
        },
        "modules": [
            "break",
            "break",
            "break",
            {
                "type": "custom",
                "format": "\u001b[90m\uf192  \u001b[31m\uf192  \u001b[32m\uf192  \u001b[33m\uf192  \u001b[34m\uf192  \u001b[35m\uf192  \u001b[36m\uf192  \u001b[37m\uf192"
            },
            "break",
            {
                "type": "title",
                "keyWidth": 10
            },
            "break",
            {
                "type": "os",
                "key": "\uf303 ",
                "keyColor": "34"
            },
            {
                "type": "kernel",
                "key": "\uf013 ",
                "keyColor": "34"
            },
            {
                "type": "packages",
                "format": "{nix-system} (nix-system), {nix-user} (nix-user)",
                "key": "\ueb29 ",
                "keyColor": "34"
            },
            {
                "type": "shell",
                "key": "\uf120 ",
                "keyColor": "34"
            },
            {
                "type": "terminal",
                "key": "\uf489 ",
                "keyColor": "34"
            },
            {
                "type": "wm",
                "key": "\uf488 ",
                "keyColor": "34"
            },
            {
                "type": "cursor",
                "key": "\ue623 ",
                "keyColor": "34"
            },
            {
                "type": "terminalfont",
                "key": "\uf031 ",
                "keyColor": "34"
            },
            {
                "type": "uptime",
                "key": "\ue385 ",
                "keyColor": "34"
            },
            {
                "type": "datetime",
                "format": "{1}-{3}-{11}",
                "key": "\uf133 ",
                "keyColor": "34"
            },
            {
                "type": "media",
                "key": "\udb81\udf5a ",
                "keyColor": "34"
            },
            {
                "type": "player",
                "key": "\uf1bc ",
                "keyColor": "34"
            },
            "break",
            {
                "type": "custom",
                "format": "\u001b[90m\uf192  \u001b[31m\uf192  \u001b[32m\uf192  \u001b[33m\uf192  \u001b[34m\uf192  \u001b[35m\uf192  \u001b[36m\uf192  \u001b[37m\uf192"
            },
            "break",
            "break"
        ]
    }
  '';
}
