#!/usr/bin/env bash
# Verify a delivery branch before anything from it is published (macula-codex).
#
# Usage: scripts/verify_delivery.sh <branch> <base-ref>
# Prints the files to publish, one per line, on success. Refuses (exit 1) when:
#   - the branch is not a known delivery branch (each has exactly one signing identity);
#   - the branch changes anything but files at the repository root (no directories, no .github);
#   - a delivered file has no <file>.sigstore.json bundle, or a bundle has no file;
#   - a bundle does not verify against the branch's exact workflow identity, or does verify
#     against a different one (a negative control, so a broken check cannot pass silently).
set -euo pipefail

BRANCH="$1"
BASE="$2"
ISSUER="https://token.actions.githubusercontent.com"

IDENTITY="$("$(dirname "$0")/identity.sh" "$BRANCH")"

refuse() { echo "REFUSED: $*" >&2; exit 1; }

changes="$(git diff --name-status --no-renames "$BASE"...HEAD)"
[ -n "$changes" ] || refuse "$BRANCH delivers nothing"

files=()
while IFS=$'\t' read -r status path; do
  [ "$status" = "A" ] || [ "$status" = "M" ] || refuse "$path: status $status (only added or changed files)"
  [[ "$path" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || refuse "$path: only plain files at the root"
  files+=("$path")
done <<< "$changes"

delivered=()
for f in "${files[@]}"; do
  case "$f" in
    *.sigstore.json) [ -f "${f%.sigstore.json}" ] || refuse "$f has no file" ;;
    *) [ -f "$f.sigstore.json" ] || refuse "$f has no bundle"
       printf '%s\n' "${files[@]}" | grep -qxF "$f.sigstore.json" || refuse "$f.sigstore.json was not delivered with $f"
       delivered+=("$f") ;;
  esac
done
printf '%s\n' "${delivered[@]}" | grep -q '\.pdf$' || refuse "$BRANCH delivers no PDF"

for f in "${delivered[@]}"; do
  cosign verify-blob --bundle "$f.sigstore.json" \
    --certificate-identity "$IDENTITY" --certificate-oidc-issuer "$ISSUER" "$f" >&2 \
    || refuse "$f: signature does not verify against $IDENTITY"
  if cosign verify-blob --bundle "$f.sigstore.json" \
       --certificate-identity "${IDENTITY}x" --certificate-oidc-issuer "$ISSUER" "$f" >/dev/null 2>&1; then
    refuse "$f: verified against a wrong identity; the check is broken"
  fi
done

for f in "${delivered[@]}"; do printf '%s\n%s\n' "$f" "$f.sigstore.json"; done
