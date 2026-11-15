#!/usr/bin/env bash
# Every 2 minutes: STALL when no model was added to the library for 6 minutes (the downloader is stuck);
# a progress line every 30 minutes otherwise.
PLACED="/c/Ai kiem tien/products/lowpoly-library/_state/placed.json"
i=0
while true; do
  age=$(( $(date +%s) - $(stat -c %Y "$PLACED") ))
  n=$(grep -o '": "' "$PLACED" 2>/dev/null | wc -l)
  if [ "$age" -gt 360 ]; then
    echo "STALL: no download for $((age / 60)) min, library at $n models"
  elif [ $((i % 15)) -eq 0 ]; then
    echo "progress: $n models in library"
  fi
  i=$((i + 1))
  sleep 120
done
