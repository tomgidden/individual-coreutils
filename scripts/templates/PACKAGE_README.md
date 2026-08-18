# individual-coreutils: {{UTIL}}

GNU coreutils' `{{UTIL}}`, built standalone from coreutils {{CU_VERSION}}
source, without building or installing the rest of coreutils. See
https://github.com/tomgidden/individual-coreutils for why this exists.

## Install

    ./install.sh

Installs `g{{UTIL}}` into `~/.local/bin` (no sudo). If nothing on your
system already provides a `{{UTIL}}` command, also symlinks a plain
`{{UTIL}} -> g{{UTIL}}` -- this project never overwrites or shadows an
existing system tool.

For a system-wide install instead:

    sudo ./install.sh --prefix /usr/local/bin

To remove what this script installed:

    ./install.sh --uninstall

## Gatekeeper / quarantine

This binary isn't code-signed or notarized (that needs a paid Apple
Developer account this project doesn't have). If you downloaded this
archive via a browser or another tool that sets macOS's quarantine
flag, running g{{UTIL}} will be blocked with "Apple could not verify
'g{{UTIL}}' is free of malware...".

`install.sh` won't clear this automatically -- that's your call, not
something a script should silently decide for you. Either:

    ./install.sh --quarantine

or clear it yourself and re-run install normally:

    xattr -dr com.apple.quarantine .

## Manual install

If you'd rather not run the script:

    install -d -m 755 ~/.local/bin
    install -m 755 bin/g{{UTIL}} ~/.local/bin/g{{UTIL}}

    # only if you don't already have a '{{UTIL}}' command:
    ln -s ~/.local/bin/g{{UTIL}} ~/.local/bin/{{UTIL}}

## Why "g{{UTIL}}"?

Homebrew's own `coreutils` formula prefixes every GNU tool with `g` to
avoid silently shadowing the BSD/Apple tool of the same name (their
behaviour can differ in real ways). This package follows that
convention for consistency, and only offers an unprefixed symlink when
your system has no tool by that name at all -- so there's nothing to
shadow.

## License

GNU coreutils is licensed GPLv3+. See LICENSE.
