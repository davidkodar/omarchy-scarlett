#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/davidkodar.scarlett"
shell_config="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"
[[ -x "$project_dir/bin/scarlett-helper" ]] || { echo 'Run make before installing.' >&2; exit 1; }
command -v omarchy >/dev/null
omarchy-shell shell ping >/dev/null
if [[ -e "$plugin_dir" || -L "$plugin_dir" ]]; then
  [[ -L "$plugin_dir" && $(readlink -f -- "$plugin_dir") == "$project_dir" ]] || {
    echo "Refusing to replace existing installation: $plugin_dir" >&2; exit 1;
  }
else
  mkdir -p -- "$(dirname -- "$plugin_dir")"
  ln -s -- "$project_dir" "$plugin_dir"
fi
if [[ -f "$shell_config" ]]; then
  backup=$(mktemp "${shell_config}.scarlett-backup.XXXXXX")
  cp -p -- "$shell_config" "$backup"
  echo "Shell configuration backup: $backup"
fi
omarchy-shell shell rescanPlugins
# The registry scan is asynchronous. Wait for discovery, not an arbitrary delay.
for attempt in {1..30}; do
  if omarchy-shell shell listPlugins | jq -e 'any(.[]; .id == "davidkodar.scarlett")' >/dev/null; then
    omarchy plugin enable davidkodar.scarlett --section right --after omarchy.audio
    exit 0
  fi
  sleep 0.2
done
echo 'Plugin discovery timed out; installation is linked but not enabled.' >&2
exit 1
