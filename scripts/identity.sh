#!/usr/bin/env bash
# The one workflow identity allowed to sign what a delivery branch carries (macula-codex).
# Usage: scripts/identity.sh <branch>    prints the exact certificate identity, or refuses.
set -euo pipefail
case "${1:-}" in
  readme-pdf)   echo "https://github.com/macula-io/macula-ecosystem/.github/workflows/readme-pdf.yml@refs/heads/main" ;;
  register-pdf) echo "https://github.com/macula-io/macula-architecture/.github/workflows/security-register-export.yml@refs/heads/main" ;;
  *) echo "REFUSED: ${1:-<none>} is not a delivery branch" >&2; exit 1 ;;
esac
