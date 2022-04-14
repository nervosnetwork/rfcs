#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

function gherr() {
  local line="$1"
  local file="${line%%:*}"
  local lineno="${line#*:}"
  lineno="${lineno%%:*}"
  local matching="${line#*:*:}"
  echo "::error file=${file#./},line=$lineno::Broken link $matching"
}

function check() {
  local line dir link target failed=0

  while read line; do
    dir="$(dirname "${line%%:*}")"
    link="${line#*:*:}"

    case "$link" in
      //*)
        # ignore http links
        ;;
      /*)
        fail "Not a valid local link"
        ;;
      ../*)
        target="$(dirname "$dir")${link#..}"
        if ! [ -f "$target" ]; then
          failed=1
          gherr "$line"
        fi
        ;;
      *)
        # relative to current directory
        target="$dir/${link#./}"
        if ! [ -f "$target" ]; then
          failed=1
          gherr "$line"
        fi
        ;;
    esac
  done

  exit "$failed"
}

find . -name '*.md' -print0 | xargs -0 /usr/bin/grep -Hno '[^(): ][^():]*\.md' | check
