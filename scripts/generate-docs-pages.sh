#!/usr/bin/env bash
# Generates docs/<name>.md (flat, at the docs root, for short URLs
# like individual-coreutils.gid.cx/timeout) for each utility in
# utils.txt, from that utility's man page in the latest GitHub
# release. Run before `docmd build` in the Pages workflow; output is
# never committed -- regenerated fresh each deploy so it can't drift
# from the man pages actually shipped in the latest release.
#
# Needs: gh (authenticated), docker (for pandoc/core -- keeps pandoc
# off the runner's own toolchain, same reasoning as this whole project
# avoiding unnecessary installs).
#
# Usage: scripts/generate-docs-pages.sh [util ...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="tomgidden/individual-coreutils"
DOCS_DIR="${ROOT_DIR}/docs"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

utils=("$@")
if [[ ${#utils[@]} -eq 0 ]]; then
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | tr -d '[:space:]')"
    [[ -z "$line" ]] && continue
    utils+=("$line")
  done < "${ROOT_DIR}/utils.txt"
fi

latest_tag="$(gh release list --repo "$REPO" --limit 1 --json tagName --jq '.[0].tagName')"
release_url="https://github.com/${REPO}/releases/tag/${latest_tag}"
echo "==> Latest release: $latest_tag"

mkdir -p "$DOCS_DIR"

for u in "${utils[@]}"; do
  echo "==> $u"
  asset_pattern="individual-coreutils-${u}-*-arm64-apple-darwin.tar.gz"
  gh release download "$latest_tag" --repo "$REPO" \
    --pattern "$asset_pattern" \
    --dir "$WORK_DIR" --clobber

  archive="$(find "$WORK_DIR" -maxdepth 1 -name "individual-coreutils-${u}-*-arm64-apple-darwin.tar.gz" | head -1)"
  if [[ -z "$archive" ]]; then
    echo "generate-docs-pages.sh: no release asset found for $u, skipping" >&2
    continue
  fi

  extract_dir="$WORK_DIR/$u"
  mkdir -p "$extract_dir"
  tar xzf "$archive" -C "$extract_dir"

  man_page="$extract_dir/share/man/man1/g$u.1"
  if [[ ! -f "$man_page" ]]; then
    echo "generate-docs-pages.sh: no man page for $u, skipping man content" >&2
    body=""
  else
    body="$(docker run --rm -v "$WORK_DIR:/data" --user "$(id -u):$(id -g)" \
      pandoc/core -f man -t gfm "/data/$u/share/man/man1/g$u.1")"
  fi

  {
    echo "# $u"
    echo ""
    echo "GNU coreutils' \`$u\` (installed as \`g$u\`), built standalone (part of [individual-coreutils]($release_url))."
    echo ""
    echo "[Download this release]($release_url) --"
    echo "[install instructions](/#install) -- [Homebrew tap](/homebrew)"
    echo ""
    echo "## Manual page"
    echo ""
    if [[ -n "$body" ]]; then
      echo "$body"
    else
      echo "(No man page available for this utility.)"
    fi
  } > "$DOCS_DIR/$u.md"
  echo "    wrote docs/$u.md"
done
