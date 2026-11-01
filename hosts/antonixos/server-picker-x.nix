{ lib, writeShellScript, writeShellScriptBin, writeTextDir, makeDesktopItem
, symlinkJoin, fetchzip, iptables }:

# Server Picker X — blocks CS2/Deadlock relay regions via `sudo iptables`.
# The upstream release binary runs through nix-ld. It writes its log next to
# itself and settings.json into the cwd, so the launcher copies the release
# into a writable data dir and runs it from there.
#
# The app's `sudo iptables …` calls hit a `sudo` shim on its PATH that runs a
# root helper through pkexec (polkit prompt, kept for a few minutes). The
# helper only accepts the app's three commands and moves its INPUT rules into
# a dedicated chain jumped to at the top of INPUT: appended to INPUT they'd sit
# behind nixos-fw's ESTABLISHED accept and never match. The app's "reset
# firewall" (`iptables -F`) then flushes only that chain.
let
  version = "1.2.0";
  chain = "server-picker-x";
  actionId = "com.github.fn-fal113.serverpickerx.iptables";

  release = fetchzip {
    url = "https://github.com/FN-FAL113/server-picker-x/releases/download/v${version}/ServerPickerX-Linux.tar.gz";
    hash = "sha256-KEEA2T9PLczTbKePBJ9Oou8nyhk3gAdshrR9oc1ph4Y=";
    stripRoot = false;
  };

  helper = writeShellScript "server-picker-x-iptables" ''
    set -eu
    ipt=${iptables}/bin/iptables
    $ipt -w -N ${chain} 2>/dev/null || true
    $ipt -w -C INPUT -j ${chain} 2>/dev/null || $ipt -w -I INPUT 1 -j ${chain}
    case "$*" in
      "-F") exec $ipt -w -F ${chain} ;;
    esac
    if [ "$#" -eq 6 ] && [ "$2" = INPUT ] && [ "$3" = -s ] && [ "$5 $6" = "-j DROP" ]; then
      case "$1" in
        -A|-D) exec $ipt -w "$1" ${chain} -s "$4" -j DROP ;;
      esac
    fi
    echo "server-picker-x: refusing iptables $*" >&2
    exit 1
  '';

  sudoShim = writeShellScriptBin "sudo" ''
    if [ "''${1-}" = iptables ]; then
      shift
      exec /run/wrappers/bin/pkexec ${helper} "$@"
    fi
    echo "server-picker-x: only iptables is allowed through sudo" >&2
    exit 1
  '';

  launcher = writeShellScriptBin "server-picker-x" ''
    dir="''${XDG_DATA_HOME:-$HOME/.local/share}/server-picker-x"
    mkdir -p "$dir"
    cp -rT --no-preserve=mode ${release} "$dir"
    chmod +x "$dir/ServerPickerX"
    cd "$dir"
    PATH=${sudoShim}/bin:$PATH exec ./ServerPickerX
  '';

  policy = writeTextDir "share/polkit-1/actions/${actionId}.policy" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
      "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
    <policyconfig>
      <action id="${actionId}">
        <description>Block game server relays</description>
        <message>Server Picker X needs to change firewall rules</message>
        <defaults>
          <allow_any>auth_admin</allow_any>
          <allow_inactive>auth_admin</allow_inactive>
          <allow_active>auth_admin_keep</allow_active>
        </defaults>
        <annotate key="org.freedesktop.policykit.exec.path">${helper}</annotate>
      </action>
    </policyconfig>
  '';

  desktopItem = makeDesktopItem {
    name = "server-picker-x";
    desktopName = "Server Picker X";
    comment = "Block CS2/Deadlock server regions";
    exec = "server-picker-x";
    categories = [ "Game" "Network" ];
  };
in
symlinkJoin {
  name = "server-picker-x-${version}";
  paths = [ launcher policy desktopItem ];
  meta.license = lib.licenses.gpl3Only;
}
