#!/usr/bin/env bash
# Evaluate every host's toplevel derivation. Builds nothing, needs no secrets:
# this is the `nix eval ... drvPath` check from AGENTS.md, run for all hosts and
# reporting every failure rather than stopping at the first.
set -uo pipefail

failed=()
for host in antonixos xps13 bank; do
  echo "::group::$host"
  if nix eval --no-write-lock-file \
      ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath"; then
    echo "$host ok"
  else
    failed+=("$host")
  fi
  echo "::endgroup::"
done

if [ "${#failed[@]}" -ne 0 ]; then
  echo "::error ::failed to evaluate: ${failed[*]}"
  exit 1
fi
