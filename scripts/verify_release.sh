#!/usr/bin/env bash
# Re-verify one published release (macula-codex): every file in it must have a bundle that
# verifies against the identity of the delivery branch named in the tag
# (<date>-<branch>-<sha7>). Prints nothing on success; refuses (exit 1) naming the problem.
#
# Usage: scripts/verify_release.sh <tag>    (needs gh and cosign; downloads into a temp dir)
set -euo pipefail
TAG="$1"
ISSUER="https://token.actions.githubusercontent.com"
refuse() { echo "REFUSED: $TAG: $*" >&2; exit 1; }

[[ "$TAG" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-(.+)-[0-9a-f]{7}$ ]] || refuse "tag is not <date>-<branch>-<sha7>"
IDENTITY="$("$(dirname "$0")/identity.sh" "${BASH_REMATCH[1]}")" || refuse "unknown delivery branch"

d="$(mktemp -d)"; trap 'rm -rf "$d"' EXIT
gh release download "$TAG" --dir "$d" >/dev/null
cd "$d"
shopt -s nullglob
any=0
for f in *; do
  case "$f" in
    *.sigstore.json) [ -f "${f%.sigstore.json}" ] || refuse "$f has no file" ;;
    *) [ -f "$f.sigstore.json" ] || refuse "$f has no bundle"
       cosign verify-blob --bundle "$f.sigstore.json" --certificate-identity "$IDENTITY" \
         --certificate-oidc-issuer "$ISSUER" "$f" >/dev/null 2>&1 || refuse "$f does not verify against $IDENTITY"
       any=1 ;;
  esac
done
[ "$any" = 1 ] || refuse "no files"
