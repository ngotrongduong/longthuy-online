#!/usr/bin/env bash
# Prints a progress line every 10 minutes and STALL when no model was placed in the last 10 minutes.
PLACED="/c/Ai kiem tien/products/lowpoly-library/_state/placed.json"
last=-1
while true; do
  n=$(grep -o '": "' "$PLACED" 2>/dev/null | wc -l)
  if [ "$n" -eq "$last" ]; then
    echo "STALL: library still at $n models after 10 min"
  else
    echo "progress: $n models in library"
  fi
  last=$n
  sleep 600
done
