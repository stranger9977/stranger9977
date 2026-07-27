---
name: animate
description: Build animated charts, title cards, and 3D play reconstructions for videos using the house Remotion pipeline. Use when creating any moving visual, setting up the animation repo, or deciding how to visualize a finding. Triggers on "animate this", "make the chart move", "build the scene", "3D play diagram", "render the video".
---

# Animate

The house animation pipeline. **Stack decision: Remotion.** The reasoning, the alternatives
considered, and the evidence are in `references/stack-decision.md` — read it once, then
don't relitigate it.

**Remotion ships its own maintained agent skill.** Install it and let it handle React and
Remotion mechanics:

```bash
npx skills add remotion-dev/skills
```

That's 28 vendor-maintained rule files covering the composition model, `interpolate()`,
`spring()`, `Sequence`/`Series`, transitions, and audio. **This skill does not duplicate
that.** This file covers the house-specific layer: the data contract, the theme, the timing
spine, and the sports-specific components.

Also load the **`dataviz`** skill before choosing any chart form or palette.

---

## The architecture rule

This is the whole thing, and it's what keeps your expertise where it belongs:

> **Python and R compute numbers and write JSON. Remotion reads JSON and computes pixels.
> Neither crosses the line.**

```
/analysis          your Python/R. Unchanged. This is your actual expertise.
    ↓ emits
/public/data/{topic}.json
    ↓ read by
/src
  /components      reusable and versioned — Chart, LowerThird, Callout, Field
  /scenes          per-video composition
  /theme.ts        ONE file: palette, type scale, spacing, easing
```

Consequences worth naming:

- Your analysis stays fully testable in the language you're expert in.
- The video layer becomes a **pure rendering function of committed data** — re-render any
  video from any commit and get a byte-similar file.
- A correction to a number is a JSON change and a re-render, not an editing session.
- **Never** compute a statistic inside a React component. If a number appears on screen, it
  came from the JSON, which came from analysis code you can point at.

## Hard rules

**Every animated value derives from `useCurrentFrame()`.** Remotion renders by seeking to
discrete frames, not by playing in real time. Any third-party animation driven by
`requestAnimationFrame` will flicker.

- **D3: use the math, never the transitions.** `d3-scale`, `d3-shape`, `d3-array`,
  `d3-geo`, `d3-axis` are pure functions and are exactly right. Never `d3-transition` or
  `.transition()`. You compute the path for frame N and render it as React SVG.
- **Recharts:** usable, second choice. Set `isAnimationActive={false}` and drive externally.
  It fights you on editorial typography.
- **`@remotion/paths`** for line-draw-on effects.
- **3D:** drive from `useCurrentFrame()`, **never** `useFrame()`. Set `layout="none"` on any
  `<Sequence>` inside `<ThreeCanvas>`.

## The three things to build, in order

### 1. The data contract, theme, and one chart component

Before any animation. Build `theme.ts` first — a single locked type scale, palette, spacing
and easing set. **This is what makes forty charts look like one magazine instead of forty
charts.** Pull the palette and form decisions from the `dataviz` skill and the visual
language already established in the five *Against the Book* articles.

Then build exactly one component: an animated bar or line chart driven by a JSON spec —
data path, title, kicker, source line, highlight rule, annotations. `d3-scale` for math,
`interpolate()`/`spring()` for motion, `@remotion/paths` for draw-on.

This is the highest-leverage hour in the whole project. Every future video is cheaper for it.

### 2. The narration-locked timing spine

Record VO first. Then:

```
@remotion/install-whisper-cpp
  → transcribe({ tokenLevelTimestamps: true })
  → toCaptions()
  → { text, startMs, endMs, confidence }
```

**Derive every scene boundary and chart beat from those timestamps.** Put named markers in
the script, resolve them to millisecond offsets from the transcript, and let scene durations
be *computed rather than typed*. This is manim-voiceover's bookmark idea, and it's the best
idea in that ecosystem — worth stealing wholesale.

Why this is second and not fifth: manual timing is where solo animators lose weekends, and
where re-recording one line becomes a two-hour re-timing job. With narration driving timing
programmatically, changing a sentence costs one re-render and zero manual work.

**This is the difference between a pipeline and a craft project.** It also gives you
burned-in captions for free.

### 3. One 3D play reconstruction in `@remotion/three`

Build this third, but inside the first month — it's the riskiest assumption in the plan. If
`@remotion/three` can't deliver the Fern-adjacent look, find out while the sunk cost is
20 hours rather than 200.

- Field plane with yard lines and hashes **generated procedurally from real dimensions**,
  not a purchased stadium asset. Procedural means parameterized, which means deterministic.
- Player positions from tracking data. `nfl-tracks` and the Big Data Bowl notebooks are good
  references for the data shape even though you won't render with them.
- **Constraint:** public NFL tracking data is 2D only — x ≈ 0–120 yards, y ≈ 0–53.3. Your
  third dimension is **camera and staging**, not player elevation.
- Camera path as a JSON keyframe list, interpolated by frame.

## Rendering

```bash
npx remotion studio                 # live preview while building
npx remotion render <Comp> out.mp4  # headless, code → uploadable MP4
npx remotion benchmark              # find your optimal --concurrency
```

There is no compositing step. Sequencing is `<Series>` and `<Sequence from= durationInFrames=>`,
audio is `<Audio>`, and the render emits a finished file.

Render is headless Chrome, frame by frame, and it is **CPU-bound and not fast**. Both
too-high and too-low `--concurrency` hurt — benchmark it once and record the number. Budget
real wall-clock for a long render and run it while you do something else.

## What this costs you honestly

**You have to learn enough React to be dangerous — roughly 10–15 hours.** That's the real
objection and it shouldn't be minimized.

Two things make it tolerable. React's model is declarative — *given this state, describe
this frame* — which is much closer to how you already think in ggplot and matplotlib than
any timeline GUI is. And frame-as-pure-function-of-`useCurrentFrame()` is exactly the
determinism you asked for, enforced by the framework instead of by your discipline.

**Licensing:** free for individuals and companies of 3 or fewer employees, permanently,
commercial use included. At 4+ employees it's $25/seat/month. Not a trap.

**If React genuinely blocks you** after two weeks — blocking, not merely annoying — fall
back to **Manim plus manim-voiceover** and accept a more lecture-flavored aesthetic. Do not
fall back to Blender; that's a bigger jump, not a smaller one.

**Blender:** don't touch it for at least three months. Prove the channel works first. Add it
only if `@remotion/three` demonstrably can't get the look, and pin **4.5 LTS** when you do.

## What this means for cadence

Programmatic pipelines have a brutal upfront cost and then a genuine collapse as the
component library compounds.

| | First 2–3 videos | After ~6 months with a library |
|---|---|---|
| Hours per finished minute | **12–20** | **2–4** |

At one hour a day, an intermediate 7-minute video is roughly 14–28 hours — **two to four
weeks.** A 12-minute flagship is five to six weeks.

**The first video will take three to four times that. Plan for it to be miserable and ship
it anyway.**

## The closing perspective

Every reference channel wins on writing and structure. Only Kurzgesagt wins on production
value, and Kurzgesagt is ~120 hours per finished minute — unreproducible by definition.

**Jon Bois wins with Google Sheets charts and Google Earth.** His tooling is aggressively
unimpressive and he's the most relevant model you have. Tool selection is maybe 20% of the
outcome.

Pick Remotion, stop researching, and go make the ugly first video.
