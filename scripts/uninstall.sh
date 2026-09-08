#!/usr/bin/env bash
# Disable this plugin and remove only a link to this checkout. Keep all source.
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/davidkodar.scarlett"
shell_config="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"
if [[ ! -e "$plugin_dir" && ! -L "$plugin_dir" ]]; then
  echo 'Scarlett is not installed.'; exit 0
fi
[[ $(readlink -f -- "$plugin_dir") == "$project_dir" ]] || {
  echo 'Refusing to change an installation owned by another checkout.' >&2; exit 1;
}
if [[ -f "$shell_config" ]]; then
  backup=$(mktemp "${shell_config}.scarlett-backup.XXXXXX")
  cp -p -- "$shell_config" "$backup"
  echo "Shell configuration backup: $backup"
fi
omarchy plugin disable davidkodar.scarlett
if [[ -L "$plugin_dir" ]]; then
  unlink -- "$plugin_dir"
  omarchy-shell shell rescanPlugins
else
  echo 'Plugin disabled. Its source checkout remains in the plugin directory.'
fi
