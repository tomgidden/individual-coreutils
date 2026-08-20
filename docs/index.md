# individual-coreutils

Standalone builds of GNU coreutils utilities for macOS, one binary (or
`.tar.gz`) per utility, without installing all of coreutils in one go,
without a package manager, and without runtime dependencies beyond the
system libc.

## Why

The usual way to get GNU coreutils on macOS is `brew install coreutils`,
which builds and installs the *entire* suite as one unit, prefixed with
`g` so it doesn't collide with the BSD/Apple tools macOS already ships
(`ls`, `cp`, `date`, `chmod`, ...). That's fine if you want everything,
but it's an all-or-nothing install, and Homebrew itself as a dependency.

This project builds the same ~105 utilities individually. Each has its
own page with usage details and download links -- see
[`utils.txt`](https://github.com/tomgidden/individual-coreutils/blob/main/utils.txt)
in the repo for the current list and rationale (including the couple
of utilities that don't build on macOS at all), or grab any of them
directly from the [Releases page](https://github.com/tomgidden/individual-coreutils/releases).

(Installed binary is `g<name>`, e.g. `gtimeout` -- see
[Why "g" prefixed?](#why-g-prefixed) below for when the plain name is
also available.)

## Install

Grab a release for your Mac from the
[Releases page](https://github.com/tomgidden/individual-coreutils/releases)
-- one archive per utility. Extract it and run:

```
./install.sh
```

This installs `gtimeout` (etc) into `~/.local/bin`. If nothing on your
system already provides a plain `timeout` command, it also symlinks
`timeout -> gtimeout`. See `--prefix`, `--no-plain`, `--quarantine`,
and `--uninstall` options, and each utility's page for details.

Prefer Homebrew? See the [Homebrew tap](/homebrew) page.

## Why "g" prefixed?

Matches the existing Homebrew `coreutils` convention, so `gtimeout`
means the same thing everywhere. A plain, unprefixed name is only ever
symlinked in at *install* time, and only when nothing on that specific
machine already answers to that name -- checked live on your machine,
not assumed at build time, since that's the only place "already taken"
can be judged correctly.

## Building from source

Needs a C compiler (Xcode Command Line Tools) and either:

- **`scripts/build-tarball.sh`** (recommended, what releases use):
  downloads the official coreutils release tarball, verifies its GPG
  signature against the maintainer's known key, and builds. Needs
  `gpg`. No autotools required -- release tarballs ship a pre-generated
  `configure`.
- **`scripts/build-git.sh`**: builds straight from a git checkout of
  the latest tag instead, running `./bootstrap` to generate `configure`.
  Needs the full GNU autotools chain. This exists as a canary against
  upstream build-system breakage, not as the everyday route.

Both scripts force off optional external libraries (GMP, SELinux,
libcap, xattr support) so the resulting binaries link only against
macOS system libraries, regardless of what happens to be installed on
the build machine.

Full details in the [repo README](https://github.com/tomgidden/individual-coreutils#readme).

## License

GNU coreutils is licensed GPLv3+. See `LICENSE` in each release
archive.
