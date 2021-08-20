#!/usr/bin/env bash

set -e
set -u
[ -n "${DEBUG:-}" ] && set -x || true

mkdir -p src
rsync -avu --delete --progress -h rfcs/ src/rfcs/
cp -f README.md src/introduction.md

printf '[Introduction](introduction.md)\n\n' > src/SUMMARY.md

for dir in $(find rfcs -depth 1 | sort); do
  slug="$(basename "$dir")"
  rfc_no="${slug%%-*}"
  index_md="$dir/$slug.md"
  if [ -f "$index_md" ]; then
    title="$(head -n 42 "$index_md" | sed -n 's/^# //p' | head -n 1)"
    if [ -n "$title" ]; then
      printf -- '- [RFC%s %s](%s)\n' "$rfc_no" "$title" "$index_md" >> src/SUMMARY.md
    else
      echo "Missing title in $index_md" >&2
    fi

    # YAML front matters
    if [ "$(head -n 1 "$index_md")" = '---' ]; then
      awk '{ if (/^---$/) { ++c; if (c == 1) { print "```yaml" } else if (c == 2) { print "```" } else { print } } else { print } }' "$index_md" > "src/$index_md"
    fi
  else
    echo "Missing index file in $dir" >&2
  fi
done

if [ -z "${NO_BUILD:-}" ]; then
  mdbook build
  find book -type f -name '*.html' -print0 | xargs -0 sed -i.bak 's;https://github.com/nervosnetwork/rfcs/edit/master/src/rfcs/;https://github.com/nervosnetwork/rfcs/edit/master/rfcs/;'
  find book -type f -name '*.html.bak' -delete
fi
