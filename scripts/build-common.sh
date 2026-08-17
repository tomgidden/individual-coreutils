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
  for u in "${utils[@]}"; do
    echo "==> Building $u"
    make "src/$u"

    mkdir -p "$out_dir/$u/bin" "$out_dir/$u/share/man/man1"
    cp "src/$u" "$out_dir/$u/bin/$u"

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
