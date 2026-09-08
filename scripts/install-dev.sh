#!/usr/bin/env bash
# Compatibility alias for early development instructions.
set -euo pipefail
exec "$(dirname -- "${BASH_SOURCE[0]}")/install.sh" "$@"
