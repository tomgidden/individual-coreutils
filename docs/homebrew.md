# Homebrew

Prefer a package manager? [homebrew-individual-coreutils](https://github.com/tomgidden/homebrew-individual-coreutils)
is a small tap: one formula per utility, each just downloading the
matching [release](https://github.com/tomgidden/individual-coreutils/releases)
asset from this repo. No local compiling, no build dependencies, no
duplicate `g`-prefixed copies of tools you already have.

## Install

```
brew tap tomgidden/individual-coreutils
brew trust tomgidden/individual-coreutils
brew install timeout
```

`brew trust` is a newer Homebrew safety gate for non-official taps --
without it, `brew install`/`brew tap` may refuse to load formulae from
a tap that isn't `homebrew/core`. Run it once per tap (or formula; see
`brew trust --help`).

Installs as `gtimeout`; `timeout` is symlinked to it automatically,
since nothing on stock macOS already provides a `timeout` command --
same install-time detection logic as the plain
[install.sh](/#install) path, just wired into `brew install` instead.

## Available formulae

Same list as the [utilities page](/) -- `timeout`, `nproc`, `shuf`,
`tac`, `numfmt`, `b2sum`, `shred`, `basenc`, `base32`. Swap the name in
`brew install <name>`.

## What's in the tap repo

Each `Formula/<name>.rb` is generated from an individual-coreutils
release (not hand-written -- nine near-identical files drift out of
sync fast if maintained by hand). The actual build happens here, in
individual-coreutils' CI, from official GPG-verified coreutils source;
the tap just points at the resulting release assets.
