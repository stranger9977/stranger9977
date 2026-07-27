# Amber — Joel Embiid, playoff availability

Two beliefs on trial: that seven-footers break, and that Embiid can't play hurt.

```
house.py    the theme module — palette, beat lengths, shared helpers.
            Build once; every future video inherits it.
scenes.py   the scenes. Each class is one act beat.
build.sh    render all at 1080p30 and concat -> amber.mp4
```

Requires Manim CE 0.20.1 (`pip install manim`, needs `libpango1.0-dev`) and ffmpeg.

```bash
./build.sh                                    # full film
manim -qh --fps 30 scenes.py A4_Confound      # one scene
manim -ql scenes.py A4_Confound               # fast preview while writing
```

Script: `../../scripts/amber.md`

## Status

Acts 1, 3 and 4 built — 6:35 of animation. **Act 2 (the seven-footer myth) is not
written**, pending research on whether height actually predicts injury. If that
evidence turns out thin, say so; a null is a piece.

## Every number needs verifying

All figures come from the Embiid availability article and have **not** been
re-derived. House rule: no number ships that you didn't verify.
