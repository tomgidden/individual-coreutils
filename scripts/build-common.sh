#!/usr/bin/env bash
# Shared build logic: given a ready coreutils source tree (SRC_DIR, with
# `configure` already run so a Makefile exists), build the utilities in
# utils.txt (or $@) via `make src/<name>` and stage each into
# out/<name>/{bin,share/man/man1}. Sourced by scripts/build-tarball.sh
# and scripts/build-git.sh; not meant to be run directly.

build_utils_from_configured_source() {
  local src_dir="$1"; shift
  local out_dir="$1"; shift
  local root_dir="$1"; shift
  local utils=("$@")

  if [[ ${#utils[@]} -eq 0 ]]; then
    local utils_file="${root_dir}/utils.txt"
    [[ -f "$utils_file" ]] || { echo "build: $utils_file not found" >&2; exit 1; }
    while IFS= read -r line; do
      line="${line%%#*}"
      line="$(echo "$line" | tr -d '[:space:]')"
      [[ -z "$line" ]] && continue
      utils+=("$line")
    done < "$utils_file"
  fi

  echo "==> Building: ${utils[*]}"

  rm -rf "$out_dir"
  mkdir -p "$out_dir"

  cd "$src_dir"

  # `src/<name>` targets don't declare BUILT_SOURCES (generated headers
  # like configmake.h, version.h) as make-tracked prerequisites -- only
  # the top-level `all` target does (`all: $(BUILT_SOURCES)`). Building
  # a single program target directly, as we do below, fails on a
  # from-scratch tree with "configmake.h file not found" unless we
  # generate those headers first ourselves. There's no target named
  # literally $(BUILT_SOURCES); we get make to expand the variable by
  # including the real Makefile into a throwaway one with a print rule,
  # then pass the expanded (space-separated) list back to make as
  # actual targets.
  echo "==> Generating build headers"
  local print_mk built_sources
  print_mk="$(mktemp)"
  cat > "$print_mk" <<'MAKEFRAG'
include Makefile
print-%:
	@echo '$($*)'
MAKEFRAG
  built_sources="$(make -f "$print_mk" print-BUILT_SOURCES)"
  rm -f "$print_mk"
  make $built_sources

  for u in "${utils[@]}"; do
    echo "==> Building $u"

    # coreutils builds `install` as the make target `ginstall` (its
    # local.mk avoids a name clash with make's own `install` target,
    # then transforms the name back to `install` at real `make install`
    # time). We package it under `install` -- matching its man page and
    # what every other utility here is named -- but must build the
    # `ginstall` target, since `make src/install` isn't a real rule and
    # silently falls through to make's implicit C-compile rule instead
    # (missing -DHAVE_CONFIG_H etc, so it fails on `config.h`).
    local build_target="$u"
    [[ "$u" == "install" ]] && build_target="ginstall"
    make "src/$build_target"

    mkdir -p "$out_dir/$u/bin" "$out_dir/$u/share/man/man1"
    cp "src/$build_target" "$out_dir/$u/bin/$u"

    if [[ -f "man/$u.1" ]]; then
      cp "man/$u.1" "$out_dir/$u/share/man/man1/$u.1"
    fi

    cp "$src_dir/COPYING" "$out_dir/$u/LICENSE"
  done

  echo "==> Verifying binaries link only against system libraries"
  for u in "${utils[@]}"; do
    local bad
    bad="$(otool -L "$out_dir/$u/bin/$u" | tail -n +2 | grep -v -E '/usr/lib/|/System/' || true)"
    if [[ -n "$bad" ]]; then
      echo "build: $u links against non-system libraries:" >&2
      echo "$bad" >&2
      exit 1
    fi
  done

  echo "==> Built: ${utils[*]}"
}
