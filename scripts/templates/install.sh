#!/bin/sh
# Installs g{{UTIL}} (and, if nothing on this machine already provides
# "{{UTIL}}", a plain-named symlink to it too) plus its man page.
#
# Usage:
#   ./install.sh                    # into ~/.local/bin (default, no sudo)
#   ./install.sh --prefix /usr/local/bin   # system-wide (needs sudo)
#   ./install.sh --no-plain         # only install g{{UTIL}}, skip the symlink check
#
# Only uses `install` flags common to both BSD (macOS) and GNU install:
# -d and -m. Nothing GNU-only, so this runs fine even if the system
# `install` isn't GNU's.

set -eu

UTIL="{{UTIL}}"
PREFIX="${HOME}/.local/bin"
MANPREFIX="${HOME}/.local/share/man/man1"
WANT_PLAIN=1

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)
      PREFIX="$2"
      MANPREFIX="$(dirname "$PREFIX")/share/man/man1"
      shift 2
      ;;
    --no-plain)
      WANT_PLAIN=0
      shift
      ;;
    *)
      echo "install.sh: unknown option: $1" >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

install -d -m 755 "$PREFIX"
install -m 755 "$SCRIPT_DIR/bin/g$UTIL" "$PREFIX/g$UTIL"
echo "Installed $PREFIX/g$UTIL"

if [ -f "$SCRIPT_DIR/share/man/man1/g$UTIL.1" ]; then
  install -d -m 755 "$MANPREFIX"
  install -m 644 "$SCRIPT_DIR/share/man/man1/g$UTIL.1" "$MANPREFIX/g$UTIL.1"
  echo "Installed $MANPREFIX/g$UTIL.1"
fi

if [ "$WANT_PLAIN" = "1" ]; then
  # Only symlink the plain name if nothing on this machine already
  # provides it -- checked here, at install time, on the target
  # machine, rather than baked in at build time, since what "already
  # provides it" means depends on this machine, not the build runner.
  if command -v "$UTIL" >/dev/null 2>&1; then
    echo "Note: '$UTIL' already exists on this system ($(command -v "$UTIL"))."
    echo "      Not creating a plain-named symlink -- use g$UTIL directly,"
    echo "      or run with --no-plain to silence this check next time."
  else
    ln -sf "$PREFIX/g$UTIL" "$PREFIX/$UTIL"
    echo "Installed $PREFIX/$UTIL -> g$UTIL (no existing '$UTIL' found on this system)"
  fi
fi

case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *) echo "Note: $PREFIX is not on your PATH." ;;
esac
