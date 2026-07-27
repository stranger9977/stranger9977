# Animation Stack — Decision Record

Researched July 2026. **Decision: Remotion.** Recorded so it doesn't get relitigated every
time something shiny appears, and so the reasoning can be checked if circumstances change.

Confidence is flagged. Direct page fetches were blocked by egress policy during research, so
prices and version numbers are search-extracted — **verify before you pay.**

---

## The candidates

### Remotion — **chosen**

React/TypeScript; renders video from web technology.

**Why it wins, ranked by weight:**

1. **It is the only option with a maintained first-party agent skill.** `npx skills add
   remotion-dev/skills` — 28 vendor-maintained rule files covering the composition model,
   `interpolate()`, `spring()`, `Sequence`/`Series`, transitions, audio, and charts. Given
   the goal is LLM-generated scenes, this single factor probably outweighs the rest
   combined, because it determines whether the intended workflow functions at all.
   Everything else offers hobbyist skills or nothing.
   https://www.remotion.dev/docs/ai/skills · https://github.com/remotion-dev/skills
2. **2D charts and 3D reconstruction live in one pipeline.** `@remotion/three` (React Three
   Fiber, frame-deterministic) means spatial reconstruction is a component in the same repo,
   same render command, same timeline as the charts. Every alternative forces a two-tool
   architecture — Manim + Blender, or gganimate + Blender + an NLE — with a fragile handoff.
   **At one hour a day, the seam is where the project dies.**
   https://www.remotion.dev/docs/three
3. **No compositing layer at all.** `npx remotion render` emits a finished MP4. No ffmpeg
   orchestration, no NLE daemon. This is the clean headless code→MP4 path.
4. **Layout and typography are CSS.** Flexbox, grid, web fonts, real text wrapping. The
   aesthetic target is ESPN The Magazine, which is a *typography and layout* target. CSS is
   the best layout engine that exists. Manim has no layout engine at all — this gap is
   unbridgeable and points directly at the goal.
5. **Free permanently for this use case.** Individuals and companies of ≤3 employees,
   commercial use included. $25/seat/month at 4+ employees; Automators tier $0.01/render with
   a $100/mo minimum; Enterprise from $500/mo. **[Confidence: medium-high]**
   https://www.remotion.dev/docs/license/pricing
6. **D3's math library works natively** — the scales and projections reached for in Python
   have direct, documented JS equivalents.

**Costs, honestly:**

- **~10–15 hours to learn enough React.** The real objection.
- Render is headless Chrome, frame by frame — CPU-bound and slow. Tune `--concurrency` via
  `npx remotion benchmark`; both too-high and too-low hurt. Open issue on renderer core
  underutilization (remotion-dev/remotion#4300).
- No vector "morph one equation into another" magic. Manim does that specific thing better.

**Announced but not shipped:** from Remotion 5.0, telemetry via `licenseKey` becomes
mandatory for the **Automators** tier only; stays optional for Creators. Doesn't affect a
free solo user. **[Confidence: medium]**

### Manim — **rejected, and it's the trap**

3Blue1Brown's library. Python, which is seductive given the background. Reject anyway.

**Use ManimCE if you ever do use it, not 3b1b's.** ManimCE v0.20.1 (0.20.0 released ~Feb
2026), `pip install manim`. ManimGL (1.7.x) is Grant's personal tool and the repo explicitly
says it isn't built for outside users and "drifts in unexpected directions."

**Why rejected:**

- **It is a math-lecture engine with a math-lecture aesthetic.** The target here is editorial
  design and spatial reconstruction. Optimized for neither.
- **No layout engine.** No flexbox, no real text wrap, no baseline grid. Positioning is
  `.next_to()`, `.to_edge()`, `.arrange()` and manual buffers. For kickers, decks, source
  lines, footnotes and wrapping chart titles you will hand-nudge coordinates forever.
- **Text performance is a documented, recurring problem.** Creation regressed in 0.17.3 vs
  0.17.2 with multiple text objects (issue #3221). `DecimalNumber`/`Integer`/`Text` with
  updaters get **progressively slower over a single render** (issue #1959) — exactly the
  pattern a live-updating stat counter uses.
- **Typesetting is LaTeX**, a terrible fit for editorial sports typography. Typst requested
  (#3339), not shipped.
- **3D is parametric surfaces and axes.** The docs' own tutorials say use Blender for complex
  3D. It will not produce a Fern-style play reconstruction.
- **Mid-refactor.** The contributing docs state the project *"is currently undergoing a major
  refactor, during which contributions implementing new features will not be accepted."*
  Alive and releasing, but in maintenance mode, not feature growth. **[Confidence: high the
  text exists; medium on implications]**
- **No sports or business-charting ecosystem.** `Axes`, `BarChart`, `NumberPlane`. That's it.

**Worth stealing regardless: `manim-voiceover`.** Per-word timing via Whisper; embed
`<bookmark mark="A"/>` in narration and call `self.wait_until_bookmark("A")`. Actively
maintained (Gemini TTS Dec 2025, Supertonic Jan 2026). **The best idea in that ecosystem**,
and it's the basis for the timing spine in `SKILL.md`.
https://github.com/ManimCommunity/manim-voiceover

`manim-slides` is for live presentations. Irrelevant to a YouTube pipeline.

**Fallback position:** if React genuinely blocks progress after two weeks, Manim +
manim-voiceover is the retreat, accepting a lecture-flavored aesthetic.

### Motion Canvas — **dead. [Confidence: high]**

`motioncanvas.io` returns **NXDOMAIN**. Repo last meaningful update ~Feb 2025, issues
unanswered into 2026. HN confirming: https://news.ycombinator.com/item?id=47121188

Two forks: **canvas-commons** (community) and **Revideo** (now part of Midrender, aimed at
automated ad/Shorts generation at scale, not craftsmanship).

Its actual selling point — a visual editor for *timing*, with code as source of truth — now
lives in Remotion Studio on a maintained project. **Migrate the idea, not the tool.**

### R-native (gganimate et al.) — **chart layer only, not animation layer**

gganimate v1.0.11 (May 2026), alive but slow-moving.

**Why not the animation layer:** the model is `transition_*()` + `ease_aes()`, tweening
between ggplot states. Zero control over camera, scene structure, or text choreography. No
compositing, no audio, no sequencing. **It makes one animated chart, not a video.**

**If you do use it, use `file_renderer()`** — dump a numbered PNG sequence and hand it to
ffmpeg. Avoid `ffmpeg_renderer()`: a live bug ignores the `fps` argument and outputs 25fps
regardless (#316), and macOS users report malformed MP4s from `av_renderer`/`ffmpeg_renderer`
(#340).

**`camcorder` is widely misunderstood** — it records your ggplot *iteration history* into a
making-of GIF. A design-process toy, charming for a "how I built this chart" B-roll clip.
Not a production tool.

**Correct role:** R for data wrangling, model fitting, and rapid ggplot exploration to *find*
the chart that carries the story. Then export **the numbers, not the picture**. gganimate →
PNG sequence is a legitimate 20-minute escape hatch when slammed, not an architecture.

### Blender + bpy — **defer at least three months**

The Fern path for 3D. Real, but not yet.

- **Pin 4.5 LTS** (supported to July 2027). 5.0 shipped late 2025; bpy breakage between minor
  releases is real and annoying. You want a stationary target.
- **Use EEVEE Next**, not Cycles. Seconds per frame, not minutes. A stylized field
  reconstruction does not need path tracing.
- **"Scripted Blender without learning Blender" is not a real option.** The Python is easy;
  the difficulty is that bpy is an API over a GUI's data model and assumes you have that
  model. You can't script materials without the shader node graph, or a camera move without
  Blender's rotation conventions and f-curve interpolation. Budget **~15 hours of GUI
  fundamentals**, then never open it again except to eyeball a frame. Fair trade — but budget
  it honestly.
- **Don't buy a stadium.** A regulation field is a plane, a texture and line geometry —
  generate it procedurally from dimensions in code. Buy assets only for tedious non-data-driven
  things: crowd, stands, sky.
- Geometry Nodes are right for procedural work, but building node trees in Python is verbose
  and unpleasant. Standard practice is author in the GUI, drive exposed inputs from Python.
- Headless: `blender -b scene.blend -P script.py -o //frame_ -a`. Note bpy can only be
  imported once per process.

### Web/SVG DIY (D3 + headless Chrome) — **this is Remotion, hand-rolled**

The determinism trick is Chrome's `HeadlessExperimental.beginFrame` CDP API — advance virtual
time frame-by-frame rather than screen-recording. Tools: `timecut`, `puppeteer-capture`.
Avoid `puppeteer-screen-recorder`-style real-time tools; they aren't frame-deterministic.

But Remotion is exactly this pipeline, productized, with a component model, audio, a preview
studio and an agent skill. Building it yourself is a fun weekend and a bad allocation.

**Lottie / Rive: skip.** Both are *runtime* formats for shipping animation into apps, not
*production* formats for making video. Lottie's authoring path is After Effects — the exact
thing being avoided. Rive's is its own GUI editor.

### Generative AI video — **rejected flatly**

Veo 3.1 leads on quality; Sora 2's consumer app is discontinued and its **API is scheduled
for discontinuation September 2026** — a useful reminder about building on hosted models.

Fails on every axis of the brief:

1. **Non-deterministic by construction.** Same prompt, different output.
2. **8–20 second horizon** against a 12-minute narrative unit.
3. **It cannot render a number correctly.** Every chart, stat, jersey number and yard line
   will be wrong. For a data channel this is disqualifying.
4. **It destroys the copyright argument.** Animation was chosen for zero copyright exposure.
   Generative video's training-data provenance is the most actively litigated question in the
   medium. That trades a solved problem for an unsolved one.

Tools marketing "deterministic control" mean *more steerable*, not *reproducible*.

---

## What the reference channels actually run

| Channel | Stack | Confidence | Reproducible solo? |
|---|---|---|---|
| **Kurzgesagt** | Illustrator → After Effects (+ some Cinema 4D). **1200+ hours per 10-min video.** | High | **No.** ~120 hrs/finished-minute. At 1hr/day that's a video every 33 years. |
| **Fern** | Blender, primarily. Started as two students; now ~60 people, majority stake taken by Electrify Video Partners in early 2025. | High on Blender, medium on the AE compositing step | The look partially, at reduced scope. **The Fern you're targeting is the two-student version, not today's.** |
| **Veritasium** | After Effects, Google Earth Studio, Unreal, DaVinci Fusion; much outsourced to freelancers — **and some visuals built in Python** (Jonny Hyman). | Medium-high | Partially — and it's the most encouraging datapoint here: Python-authored visuals can carry a top-tier science channel. |
| **Jon Bois** | **Google Sheets charts + Google Earth as an animation canvas**, assembled in a conventional editor. | High | **Yes, and he's the most relevant model.** |

**The most important line:** Bois's stack is a spreadsheet and a mapping app. **Your ceiling
is not set by your renderer.**

## Hours per finished minute

Agency motion graphics run 30–60 hrs/min; Kurzgesagt ≈120. Programmatic pipelines have a
different curve — brutal upfront, then a real collapse as the component library compounds.

| Approach | Beginner | Intermediate (~6mo, with library) |
|---|---|---|
| **Remotion** | 12–20 | **2–4** |
| Manim | 8–14 | 3–6 |
| Blender scripted | 25–40 | 6–12 |
| gganimate + ffmpeg | 4–8 | 2–4 (never becomes a video pipeline) |
| D3 + headless Chrome DIY | 20–35 | 3–5 |
| After Effects | 40–80 | 15–30 |

Remotion starts worst and ends best, because components are reusable across every future
video. That crossover is the entire bet.

## Revisit conditions

Reopen this decision if:

- React proves genuinely blocking after a fair two-week attempt → Manim + manim-voiceover
- `@remotion/three` can't deliver the spatial look after an honest attempt → add Blender 4.5 LTS
- Remotion's license terms change materially for solo creators
- ManimCE exits its refactor with a real layout engine
