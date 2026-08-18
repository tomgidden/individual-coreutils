# individual-coreutils

Standalone builds of the handful of GNU coreutils utilities that macOS
doesn't already ship an equivalent of, without installing all of
coreutils, without a package manager, and without runtime dependencies
beyond the system libc.

## Why

macOS ships a full BSD/Apple userland (`ls`, `cp`, `date`, `chmod`, ...)
that already covers almost all of GNU coreutils. The usual way to get
the handful of genuinely missing tools (`timeout`, `shuf`, `nproc`, ...)
is `brew install coreutils`, which builds and installs the *entire*
GNU suite -- around 100 binaries, most of them duplicates of tools you
already have, prefixed with `g` so they don't collide.

This project builds only the utilities that fill a real gap. Each has
its own page with usage details and download links:

- [timeout](/timeout) -- run a command with a time limit
- [nproc](/nproc) -- print the number of available processors
- [shuf](/shuf) -- generate random permutations
- [tac](/tac) -- concatenate and print files in reverse
- [numfmt](/numfmt) -- reformat numbers
- [b2sum](/b2sum) -- BLAKE2 checksums
- [shred](/shred) -- overwrite a file to hide its contents
- [basenc](/basenc) -- base64/base32/base16/etc encode/decode
- [base32](/base32) -- base32 encode/decode

(Installed binary is `g<name>`, e.g. `gtimeout` -- see
[Why "g" prefixed?](#why-g-prefixed) below for when the plain name is
also available.)

See [`utils.txt`](https://github.com/tomgidden/individual-coreutils/blob/main/utils.txt)
in the repo for the current list and rationale.

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
