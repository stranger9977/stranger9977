#!/usr/bin/env bash
# Render every scene at 1080p30 and concat into one file.
# Deterministic: same source in, same film out.
set -euo pipefail
cd "$(dirname "$0")"
MANIM="../.venv/bin/manim"
export PATH="/usr/local/bin:$PATH"

SCENES=(A1_Setup A1_TheQuestion A3_RawSplit A3_Correction A3_Defense
        A4_Scoreboard A4_Confound A4_Everybody A4_TheRed A4_Stakes)

for s in "${SCENES[@]}"; do
  echo "--- $s"
  "$MANIM" -qh --fps 30 --disable_caching scenes.py "$s" >/dev/null 2>&1
done

OUT=media/videos/scenes/1080p30
: > concat.txt
for s in "${SCENES[@]}"; do echo "file '$OUT/$s.mp4'" >> concat.txt; done
ffmpeg -v error -f concat -safe 0 -i concat.txt -c copy -y amber.mp4
echo "built amber.mp4"
ffmpeg -i amber.mp4 2>&1 | grep Duration
