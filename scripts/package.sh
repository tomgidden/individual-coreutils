#!/usr/bin/env bash
# Package each built utility in out/<name>/ into a release archive
# containing both the g-prefixed and (for utilities marked "noconflict"
# in utils.txt) plain-named binary, man page, LICENSE, and a README.
#
# Usage: scripts/package.sh <arch-triple>
#   e.g. scripts/package.sh arm64-apple-darwin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="${ROOT_DIR}/out"
DIST_DIR="${ROOT_DIR}/dist"
ARCH="${1:?usage: package.sh <arch-triple>}"

[[ -f "$OUT_DIR/COREUTILS_VERSION" ]] || { echo "package.sh: run a build script first" >&2; exit 1; }
CU_VERSION="$(cat "$OUT_DIR/COREUTILS_VERSION")"

mkdir -p "$DIST_DIR"

for util_dir in "$OUT_DIR"/*/; do
  u="$(basename "$util_dir")"
  [[ -d "$util_dir/bin" ]] || continue

  stage="$(mktemp -d)"
  mkdir -p "$stage/bin" "$stage/share/man/man1"

  cp "$util_dir/bin/$u" "$stage/bin/g$u"
  [[ -f "$util_dir/share/man/man1/$u.1" ]] && cp "$util_dir/share/man/man1/$u.1" "$stage/share/man/man1/g$u.1"
  cp "$util_dir/LICENSE" "$stage/LICENSE"

  README="$ROOT_DIR/scripts/templates/PACKAGE_README.md"
  if [[ -f "$README" ]]; then
    sed -e "s/{{UTIL}}/$u/g" -e "s/{{CU_VERSION}}/$CU_VERSION/g" "$README" > "$stage/README.md"
  fi

  cp "$ROOT_DIR/scripts/templates/install.sh" "$stage/install.sh"
  sed -i '' -e "s/{{UTIL}}/$u/g" "$stage/install.sh"
  chmod +x "$stage/install.sh"

  archive="$DIST_DIR/individual-coreutils-${u}-${CU_VERSION}-${ARCH}.tar.gz"
  tar czf "$archive" -C "$stage" .
  rm -rf "$stage"

  echo "==> Packaged $archive"
done
