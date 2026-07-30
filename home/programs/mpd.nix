{ pkgs, ... }:

# Local MPD music daemon + rmpc TUI client. Desktop hosts only (imported from
# home/default.nix, which bank does not use).
#
# The library lives on `bank` and is mounted over Tailscale/NFS at
# /mnt/vault/data/media/music (see modules/nixos/network-share.nix) — the clean,
# organised album collection, kept separate from the /mnt/vault/data/media/yt-dlp
# download dump. That path is an on-demand automount, so MPD is set to start only
# when a client connects (network.startWhenNeeded) — that gives tailscaled and the
# automount time to come up rather than racing them at login.
{
  services.mpd = {
    enable = true;
    musicDirectory = "/mnt/vault/data/media/music";
    network.startWhenNeeded = true;

    # Play through PipeWire's PulseAudio emulation (modules/nixos/audio.nix has
    # services.pipewire.pulse.enable). Being explicit stops MPD from grabbing a
    # raw ALSA device instead of routing through PipeWire.
    extraConfig = ''
      audio_output {
        type "pulse"
        name "PipeWire (PulseAudio)"
      }
    '';
  };

  # MPRIS bridge: makes MPD show up to playerctld so the niri media keys
  # (XF86AudioPlay etc. → `playerctl --player playerctld`, config-<host>.kdl)
  # control it, exactly like Spotify. niri owns the key bindings, so mpDris2's
  # own multimedia-key grabbing stays off.
  services.mpdris2 = {
    enable = true;
    multimediaKeys = false;
  };

  home.packages = [ pkgs.rmpc ];
}
