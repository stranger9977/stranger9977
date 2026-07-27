# Amber — Joel Embiid, playoff availability

Two beliefs on trial: that seven-footers break, and that Embiid can't play hurt.

```
house.py    the theme module — palette, beat lengths, shared helpers.
            Build once; every future video inherits it.
scenes.py   Acts 1, 3, 4 — the record, the second myth, the turn.
act2.py     Act 2 — do seven-footers break? (verdict: nobody knows)
sim.py      "How we simulate" — the mechanism act. Standalone-capable.
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

**Complete: 10:30 across sixteen scenes**, rendered to `amber.mp4`.

`sim.py` is a separate 2:06 mechanism act — one game, one run, ten runs, ten thousand,
then the number. It can drop into the film before the availability findings, or ship as
its own evergreen video. See `.claude/skills/animate/references/mechanism.md` for why
that kind of piece is the channel's strongest lane.

## Every number needs verifying

All figures come from the Embiid availability article and have **not** been
re-derived. House rule: no number ships that you didn't verify.
