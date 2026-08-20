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

This project builds the same ~105 utilities individually -- grab just
`gtimeout`, or just `gshuf`, as its own small download with no package
manager and no other coreutils binaries along for the ride. See
[`utils.txt`](utils.txt) for the current list and rationale (including
the couple of utilities that don't build on macOS at all).

## Install

Grab a release for your Mac from the
[Releases page](https://github.com/tomgidden/individual-coreutils/releases)
-- one archive per utility, e.g. `individual-coreutils-timeout-9.11-arm64-apple-darwin.tar.gz`.
Extract it and run:

```
./install.sh
```

This installs `gtimeout` (etc) into `~/.local/bin`. If nothing on your
system already provides a plain `timeout` command, it also symlinks
`timeout -> gtimeout`. See the per-package README inside the archive
for details, and `--prefix`/`--no-plain`/`--uninstall` options.

Binaries aren't code-signed or notarized, so macOS may quarantine and
block them if you downloaded via a browser -- pass `--quarantine` to
`install.sh` to clear that, or see the per-package README.

Prefer Homebrew? See
[homebrew-individual-coreutils](https://github.com/tomgidden/homebrew-individual-coreutils)
(you'll also need `brew trust` -- see that repo's README).

## Why "g" prefixed?

Matches the existing Homebrew `coreutils` convention, so `gtimeout`
means the same thing everywhere. A plain, unprefixed name is only ever
symlinked in at *install* time, and only when nothing on that specific
machine already answers to that name -- checked live on your machine,
not assumed at build time, since that's the only place "already taken"
can be judged correctly.

## Building

Needs a C compiler (Xcode Command Line Tools) and either:

- **`scripts/build-tarball.sh`** (recommended, what releases use):
  downloads the official coreutils release tarball, verifies its GPG
  signature against the maintainer's known key, and builds. Needs
  `gpg`. No autotools required -- release tarballs ship a pre-generated
  `configure`.
- **`scripts/build-git.sh`**: builds straight from a git checkout of
  the latest tag instead, running `./bootstrap` to generate `configure`.
  Needs the full GNU autotools chain (autoconf, automake, autopoint,
  pkg-config, help2man, texinfo, gperf). This exists as a canary against
  upstream build-system breakage and as a tarball-independent path, not
  as the everyday route -- installing all of autotools on a machine you
  want to keep lean defeats the point of this project.

```
scripts/build-tarball.sh              # builds utils.txt
scripts/build-tarball.sh timeout nproc # or just these
scripts/package.sh arm64-apple-darwin  # stage release archives in dist/
```

Both build scripts don't pin a coreutils version -- they always build
against the latest release. The per-utility `make src/<name>` build
target has been part of coreutils' build system since 2012, so this is
expected to keep working across releases without maintenance.

### Why `--disable-nls`?

Building with gettext translations enabled isn't hard, and CI has
`gettext` available -- but coreutils' `.po` translation catalogs are
whole-project, not per-utility, so there's no way to ship a translated
`timeout` without bundling all ~45 languages' catalogs for the *entire*
suite. That runs against the whole point of this project (small,
focused, per-utility packages). If you need translated coreutils
messages, `brew install coreutils` gives you the full suite with NLS
built in.

## License

GNU coreutils is licensed GPLv3+. See `LICENSE` in each release
archive.
