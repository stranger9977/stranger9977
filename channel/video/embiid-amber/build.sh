#!/usr/bin/env bash
# Render every scene at 1080p30 and concat into one film.
# Deterministic: same source in, same film out.
set -euo pipefail
cd "$(dirname "$0")"
MANIM="../.venv/bin/manim"
export PATH="/usr/local/bin:$PATH"

# module:Scene, in narrative order
ORDER=(
  "scenes:A1_Setup" "scenes:A1_TheQuestion"
  "act2:A2_Belief" "act2:A2_TheOrigin" "act2:A2_Physics"
  "act2:A2_TheLiterature" "act2:A2_TheFoot" "act2:A2_Verdict"
  "scenes:A3_RawSplit" "scenes:A3_Correction" "scenes:A3_Defense"
  "scenes:A4_Scoreboard" "scenes:A4_Confound" "scenes:A4_Everybody"
  "scenes:A4_TheRed" "scenes:A4_Stakes"
)

: > concat.txt
for item in "${ORDER[@]}"; do
  mod="${item%%:*}"; scene="${item##*:}"
  out="media/videos/$mod/1080p30/$scene.mp4"
  if [ ! -f "$out" ]; then
    echo "--- rendering $scene"
    "$MANIM" -qh --fps 30 --disable_caching "$mod.py" "$scene" >/dev/null 2>&1
  else
    echo "--- cached $scene"
  fi
  echo "file '$out'" >> concat.txt
done

ffmpeg -v error -f concat -safe 0 -i concat.txt -c copy -y amber.mp4
echo
echo "built amber.mp4"
ffmpeg -i amber.mp4 2>&1 | grep -E "Duration|Stream #0:0"
