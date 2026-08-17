#!/usr/bin/env bash
# Secondary/canary build path: build straight from a git checkout of the
# latest release tag, running ./bootstrap to generate configure. This
# needs the full GNU autotools chain (autoconf, automake, autopoint,
# pkg-config, help2man, texinfo, gperf) which isn't worth installing on
# a machine you're trying to keep lean -- this path exists to catch
# upstream build-system breakage early and to build releases straight
# from source without depending on the tarball infra, not as the
# everyday path. CI installs the toolchain via Homebrew; this script
# assumes it's already present.
#
# Usage: scripts/build-git.sh [utility ...]

set -euo pipefail

REPO_URL="https://github.com/coreutils/coreutils.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/build-common.sh"

BUILD_DIR="${ROOT_DIR}/.build-git"
SRC_DIR="${BUILD_DIR}/coreutils"
OUT_DIR="${ROOT_DIR}/out"

for tool in autoconf automake autopoint pkg-config help2man makeinfo gperf; do
  command -v "$tool" &>/dev/null || { echo "build-git: missing $tool" >&2; exit 1; }
done

mkdir -p "$BUILD_DIR"
if [[ ! -d "$SRC_DIR" ]]; then
  echo "==> Cloning $REPO_URL"
  git clone --quiet "$REPO_URL" "$SRC_DIR"
fi

cd "$SRC_DIR"
latest_tag="$(git tag --list 'v*' --sort=-v:refname | head -1)"
echo "==> Using coreutils tag $latest_tag"
git fetch --quiet --tags
git checkout --quiet "$latest_tag"
CU_VERSION="${latest_tag#v}"

if [[ ! -f configure ]]; then
  echo "==> Bootstrapping (autoconf/automake/gnulib)"
  ./bootstrap --skip-po
fi

echo "==> Configuring (--disable-nls: see README for why)"
./configure --disable-nls --disable-year2038 >/dev/null

build_utils_from_configured_source "$SRC_DIR" "$OUT_DIR" "$ROOT_DIR" "$@"

echo "$CU_VERSION" > "$OUT_DIR/COREUTILS_VERSION"
echo "git" > "$OUT_DIR/BUILD_METHOD"
