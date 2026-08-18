#!/bin/sh
# Installs g{{UTIL}} (and, if nothing on this machine already provides
# "{{UTIL}}", a plain-named symlink to it too) plus its man page.
#
# Usage:
#   ./install.sh                    # into ~/.local/bin (default, no sudo)
#   ./install.sh --prefix /usr/local/bin   # system-wide (needs sudo)
#   ./install.sh --no-plain         # only install g{{UTIL}}, skip the symlink check
#   ./install.sh --quarantine       # also clear macOS's quarantine flag (see below)
#   ./install.sh --uninstall        # remove what this script installed
#
# Only uses `install` flags common to both BSD (macOS) and GNU install:
# -d and -m. Nothing GNU-only, so this runs fine even if the system
# `install` isn't GNU's.

set -eu

UTIL="{{UTIL}}"
PREFIX="${HOME}/.local/bin"
MANPREFIX="${HOME}/.local/share/man/man1"
WANT_PLAIN=1
WANT_QUARANTINE_CLEAR=0
WANT_UNINSTALL=0

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
    --quarantine)
      WANT_QUARANTINE_CLEAR=1
      shift
      ;;
    --uninstall)
      WANT_UNINSTALL=1
      shift
      ;;
    *)
      echo "install.sh: unknown option: $1" >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$WANT_UNINSTALL" = "1" ]; then
  removed_any=0
  if [ -e "$PREFIX/g$UTIL" ]; then
    rm -f "$PREFIX/g$UTIL"
    echo "Removed $PREFIX/g$UTIL"
    removed_any=1
  fi
  # Only remove the plain name if it's a symlink pointing at our
  # g$UTIL -- never touch it if it's a real file (some other tool, or
  # one this script declined to overwrite in the first place).
  if [ -L "$PREFIX/$UTIL" ]; then
    target="$(readlink "$PREFIX/$UTIL")"
    case "$target" in
      */g"$UTIL"|g"$UTIL")
        rm -f "$PREFIX/$UTIL"
        echo "Removed $PREFIX/$UTIL (was a symlink to g$UTIL)"
        removed_any=1
        ;;
    esac
  fi
  if [ -e "$MANPREFIX/g$UTIL.1" ]; then
    rm -f "$MANPREFIX/g$UTIL.1"
    echo "Removed $MANPREFIX/g$UTIL.1"
    removed_any=1
  fi
  if [ "$removed_any" = "0" ]; then
    echo "Nothing to remove under $PREFIX / $MANPREFIX."
  fi
  exit 0
fi

# This binary isn't signed with an Apple Developer ID or notarized (that
# needs a paid $99/yr account this project doesn't have), so if it was
# downloaded via a browser or something else that sets com.apple.quarantine,
# Gatekeeper will refuse to run it ("Apple could not verify... is free of
# malware"). We don't clear this automatically -- that's a trust decision
# only you should make, not a script silently overriding a security
# prompt on your behalf. Pass --quarantine to have this script do it, or
# run the command yourself.
if command -v xattr >/dev/null 2>&1 && xattr -p com.apple.quarantine "$SCRIPT_DIR/bin/g$UTIL" >/dev/null 2>&1; then
  if [ "$WANT_QUARANTINE_CLEAR" = "1" ]; then
    xattr -dr com.apple.quarantine "$SCRIPT_DIR"
    echo "Cleared com.apple.quarantine from $SCRIPT_DIR (--quarantine passed)."
  else
    echo "Note: g$UTIL is quarantined by macOS and will be blocked by Gatekeeper."
    echo "      Before running it, either re-run this script with --quarantine,"
    echo "      or clear it yourself:"
    echo ""
    echo "          xattr -dr com.apple.quarantine '$SCRIPT_DIR'"
    echo ""
  fi
fi

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
