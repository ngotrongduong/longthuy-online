#!/usr/bin/env bash
# Every 2 minutes: STALL when nothing new reached ~/Downloads for 6 minutes (the Meshy tab froze);
# a progress line every 30 minutes otherwise.
PLACED="/c/Ai kiem tien/products/lowpoly-library/_state/placed.json"
DL="/c/Users/ngotr/Downloads"
i=0
while true; do
  newest=$(ls -t "$DL" | head -1)
  age=$(( $(date +%s) - $(stat -c %Y "$DL/$newest") ))
  n=$(grep -o '": "' "$PLACED" 2>/dev/null | wc -l)
  if [ "$age" -gt 360 ]; then
    echo "STALL: no download for $((age / 60)) min, library at $n models"
  elif [ $((i % 15)) -eq 0 ]; then
    echo "progress: $n models in library"
  fi
  i=$((i + 1))
  sleep 120
done
