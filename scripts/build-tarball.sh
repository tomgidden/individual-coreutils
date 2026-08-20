#!/usr/bin/env bash
# Primary build path: fetch the official coreutils release tarball,
# verify its GPG signature against the known maintainer key, extract,
# configure, and build the utilities in utils.txt.
#
# Needs: curl, gpg, tar, a C compiler. No autotools -- release tarballs
# ship a pre-generated ./configure, unlike a raw git checkout.
#
# Usage: scripts/build-tarball.sh [utility ...]

set -euo pipefail

# Pádraig Brady's release-signing key, as published in signed coreutils
# release announcements on info-gnu@gnu.org (cross-checked against two
# independent releases: 9.5 and 9.11 announcements agree):
#   6C37 DC12 121A 5006 BC1D  B804 DF6F D971 3060 37D9
RELEASE_KEY_FPR="6C37DC12121A5006BC1DB804DF6FD971306037D9"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/build-common.sh"

BUILD_DIR="${ROOT_DIR}/.build-tarball"
OUT_DIR="${ROOT_DIR}/out"

# Resolve latest release version from the GNU FTP directory listing.
echo "==> Resolving latest coreutils release"
latest_line="$(curl -sSL https://ftp.gnu.org/gnu/coreutils/ \
  | grep -o 'coreutils-[0-9][0-9.]*\.tar\.xz"' \
  | sed 's/"$//' | sort -V | tail -1)"
CU_VERSION="$(echo "$latest_line" | sed -E 's/coreutils-([0-9.]+)\.tar\.xz/\1/')"
TARBALL="coreutils-${CU_VERSION}.tar.xz"
echo "==> Latest release: $CU_VERSION"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "==> Downloading $TARBALL and its signature"
curl -sSL -o "$TARBALL" "https://ftp.gnu.org/gnu/coreutils/$TARBALL"
curl -sSL -o "$TARBALL.sig" "https://ftp.gnu.org/gnu/coreutils/$TARBALL.sig"

if command -v gpg &>/dev/null; then
  echo "==> Verifying GPG signature (key $RELEASE_KEY_FPR)"
  export GNUPGHOME="$BUILD_DIR/.gnupg"
  rm -rf "$GNUPGHOME"
  mkdir -m 700 "$GNUPGHOME"

  # Prefer GNU's own published keyring (authoritative, no keyserver
  # flakiness) and only fall back to a public keyserver if that fetch
  # fails for some reason.
  echo "==> Fetching GNU keyring"
  curl -sSL -o "$BUILD_DIR/gnu-keyring.gpg" https://ftp.gnu.org/gnu/gnu-keyring.gpg
  if gpg --batch --quiet --import "$BUILD_DIR/gnu-keyring.gpg" 2>/dev/null \
      && gpg --batch --with-colons --fingerprint "$RELEASE_KEY_FPR" &>/dev/null; then
    :
  else
    echo "==> GNU keyring didn't have the key; trying a keyserver"
    gpg --batch --quiet --keyserver keys.openpgp.org --recv-keys "$RELEASE_KEY_FPR"
  fi

  fpr_check="$(gpg --batch --with-colons --fingerprint "$RELEASE_KEY_FPR" | awk -F: '/^fpr:/{print $10; exit}')"
  if [[ "$fpr_check" != "$RELEASE_KEY_FPR" ]]; then
    echo "build-tarball: could not obtain key $RELEASE_KEY_FPR" >&2
    exit 1
  fi
  gpg --batch --trust-model always --verify "$TARBALL.sig" "$TARBALL"
  echo "==> Signature OK"
else
  echo "build-tarball: gpg not found -- refusing to build from an" >&2
  echo "unverified tarball. Install gpg, or use scripts/build-git.sh" >&2
  echo "which verifies source via independent-mirror tag agreement instead." >&2
  exit 1
fi

echo "==> Extracting"
SRC_DIR="$BUILD_DIR/coreutils-$CU_VERSION"
rm -rf "$SRC_DIR"
tar xf "$TARBALL"

cd "$SRC_DIR"
echo "==> Configuring (--disable-nls: see README for why)"
# --without-libgmp etc: some optional deps get opportunistically
# detected and linked if present on the build machine (e.g. a CI
# runner or dev machine with Homebrew's gmp installed) even though
# they're not part of the base OS -- that would silently break the
# "system libraries only" property this project promises. Force them
# off explicitly rather than relying on the build machine not having
# them installed. --without-selinux/--disable-libcap are Linux-only
# features anyway; harmless to disable on macOS. --with-openssl=no
# was added after CI caught cksum dynamically linking a Homebrew-
# installed openssl@3 on the x86_64 runner (arm64 didn't have it on
# its default search path, so this only failed on Intel) -- coreutils'
# hash utilities (md5sum, sha*sum, cksum, ...) opportunistically use
# libcrypto for speed if configure finds it, same class of problem as
# libgmp above. This forces gnulib's bundled fallback implementation
# instead.
./configure \
  --disable-nls \
  --disable-year2038 \
  --without-libgmp \
  --without-selinux \
  --disable-libcap \
  --disable-xattr \
  --with-openssl=no \
  >/dev/null

build_utils_from_configured_source "$SRC_DIR" "$OUT_DIR" "$ROOT_DIR" "$@"

echo "$CU_VERSION" > "$OUT_DIR/COREUTILS_VERSION"
echo "tarball" > "$OUT_DIR/BUILD_METHOD"
