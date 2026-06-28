#!/usr/bin/env bash
set -euo pipefail

input="$1"
name=$(basename "$input" .md)
outdir="blogs/$name"
mkdir -p "$outdir"

pandoc "$input" \
  -o "$outdir/index.html" \
  --standalone \
  --css=/styles.min.css \
  --mathml \
  --syntax-highlighting=tango \
  --lua-filter=add-classes.lua

sed -i '/<meta name="generator"/d' "$outdir/index.html"