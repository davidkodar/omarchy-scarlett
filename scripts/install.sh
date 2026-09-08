#!/usr/bin/env bash
# Build locally, validate, and enable. No downloads, package installs, or sudo.
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/davidkodar.scarlett"
shell_config="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"
for tool in make cc pkg-config jq omarchy omarchy-shell; do
  command -v "$tool" >/dev/null || { echo "Missing $tool. Install base-devel, alsa-lib and json-c on an Omarchy system, then retry." >&2; exit 1; }
done
pkg-config --exists alsa json-c || { echo 'Missing development libraries: install alsa-lib and json-c, then retry.' >&2; exit 1; }
[[ $(omarchy-shell shell ping) == ok ]] || { echo 'Omarchy shell is not available.' >&2; exit 1; }
if [[ -e "$plugin_dir" || -L "$plugin_dir" ]]; then
  [[ $(readlink -f -- "$plugin_dir") == "$project_dir" ]] || {
    echo "Refusing to replace existing installation: $plugin_dir" >&2; exit 1;
  }
fi
make -C "$project_dir" all
omarchy plugin validate "$project_dir"
# All checks and the build finish before changing shell configuration.
if [[ -f "$shell_config" ]]; then
  jq -e 'type == "object" and .version == 1' "$shell_config" >/dev/null
  backup=$(mktemp "${shell_config}.scarlett-backup.XXXXXX")
  cp -p -- "$shell_config" "$backup"
  echo "Shell configuration backup: $backup"
fi
if [[ ! -e "$plugin_dir" ]]; then
  mkdir -p -- "$(dirname -- "$plugin_dir")"
  ln -s -- "$project_dir" "$plugin_dir"
fi
omarchy-shell shell rescanPlugins
for attempt in {1..30}; do
  if omarchy-shell shell listPlugins | jq -e 'any(.[]; .id == "davidkodar.scarlett")' >/dev/null; then
    placement=(--section right)
    # Reinstallation must preserve an existing user-selected position.
    if [[ -f "$shell_config" ]] && jq -e '[.bar.layout[]?[]? | select(.id? == "davidkodar.scarlett")] | length > 0' "$shell_config" >/dev/null; then
      placement=()
    elif [[ -f "$shell_config" ]] && jq -e 'any(.bar.layout.right[]?; .id? == "omarchy.audio")' "$shell_config" >/dev/null; then
      placement+=(--after omarchy.audio)
    fi
    omarchy plugin enable davidkodar.scarlett "${placement[@]}"
    echo 'Scarlett installed. If updating an already loaded plugin, run: omarchy restart shell'
    exit 0
  fi
  sleep 0.2
done
echo 'Plugin discovery timed out; installation is linked but not enabled.' >&2
exit 1
