# Mechanism, not findings

**The insight that reorganises the whole animation strategy: Manim's job is explaining
how the machine works, not reporting what it found.**

A chart reports a result. Anyone with a spreadsheet can make one, and the tool barely
matters. **Showing the method — the thing that produced the result — is a different
job, and it's the one nobody else in sports YouTube can do.**

This is 3Blue1Brown's entire channel. He does not show you the answer to a linear algebra
problem. He shows you what a matrix *does* to space, until the answer is obvious. The
transferable move is that the viewer should be able to rebuild the method from memory
afterwards.

## Why this is the moat

Every other sports channel can state a conclusion. A model is different:

- The analysis is **yours**. You built it. Nobody can copy the explanation without first
  doing the work.
- It makes the credential **visible without claiming it.** You never have to say "I'm a
  data scientist" — the audience watches you be one for two minutes.
- It's **evergreen in a way findings aren't.** "How a Monte Carlo simulation works,
  explained with playoff basketball" stays true and stays searchable for years. The 2026
  Sixers do not.
- It's the **highest-trust content you can make.** Showing your method is the strongest
  possible signal that you aren't hiding anything, and it's exactly the ethic in
  `house-style.md` — show your homework, including the traps.
- And it is **structurally footage-free**, so it carries zero Content ID exposure.

## The division of labour

| Job | Tool | Why |
|---|---|---|
| **Mechanism** — how the model works, what a distribution is, why a control matters | **Manim** | Objects that persist, transform and accumulate. This is what it was built for. |
| **Findings** — the number, the split, the comparison | Manim, or anything | The tool barely matters. Sparse beats clever. |
| **Editorial furniture** — titles, lower thirds, source lines, dense typographic hierarchy | Remotion, or an NLE | Manim has no layout engine. Don't fight it. |
| **Spatial reconstruction** — plays, routes, coverage geometry | Remotion + three, or Blender | Manim's 3D is parametric surfaces, not scenes. |

## The pattern that works

From `../../../channel/video/embiid-amber/sim.py`, and it generalises to any model:

```
1. THE ATOM        One unit of the model, alone. A single game as a weighted coin.
2. ONE DRAW        Run it once. Watch it happen. "That is one possible June."
3. A FEW DRAWS     Run it ten times. The viewer sees the variance themselves —
                   this is the beat where they understand why one run isn't an answer.
4. MANY DRAWS      Ten thousand. The distribution emerges from accumulation.
5. THE READ        Only now, a number. And show that the distribution answers
                   *any* question, not just the one you asked.
```

Five beats, roughly two minutes. **Never state the method before showing it.** The
sentence "we ran a Monte Carlo simulation" should arrive *after* the viewer has already
watched one, at which point it's a label for something they understand rather than
jargon they have to accept.

That ordering is Sanderson's concrete-before-abstract applied to methodology, and the
strong version applies too: pick the demonstration from which the viewer can derive the
general idea themselves, then let them get there half a second before you say it.

## Rules

- **The atom must be genuinely simple.** If you can't reduce the model's unit to one
  sentence — "a weighted coin with three sides" — you don't understand it well enough to
  animate it yet.
- **Show variance before showing the answer.** Beat 3 is the one everyone skips and it's
  the one that does the teaching. Ten visibly different runs is what makes the
  distribution feel necessary rather than decorative.
- **Use a fixed seed.** Same source, same film. Determinism is the point.
- **The distribution is the deliverable, not the mean.** End on what the shape lets you
  ask, not on a point estimate. "Nobody is forecasting one June. We are counting how
  often each June happens."
- **Never animate a method you didn't build.** Explaining someone else's model is a
  summary; explaining your own is the moat.

## Where this fits in a video

Mechanism acts work in two places:

**Inside a piece**, right before the finding that depends on the model. It earns the
number that follows — the viewer accepts a 2.3% because they watched where it came from.

**As its own video.** "How we simulate a playoff run" is a standalone evergreen piece,
and it's a better introduction to the channel than any finding, because it establishes
what kind of channel this is. Strong candidate for an early upload, and unusually
resistant to going stale.
