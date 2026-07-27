# Ball Knowledge / Against the Book — Operating Manual

A sports explainer channel that gives people the shared language and honest evidence to
settle the arguments they're already having.

**Start here:** `strategy/03-design-brief.md` — the criteria and constraints. It's the
document everything else is built against, and it has the open questions still worth
arguing about.

## The docs

| File | What it's for |
|---|---|
| `strategy/03-design-brief.md` | **Read first.** Product, audience, tone, cadence, skill architecture, open questions. |
| `strategy/00-strategy.md` | The five levels, the lane, monetization policy, what the research settled. |
| `strategy/01-voice.md` | The narration decision. Use your own voice; here's the evidence and the gear. |
| `strategy/02-monetization.md` | The honest arithmetic. Ads are 10–15%. What actually pays. |
| `strategy/30-day-plan.md` | Week-by-week for the first month, plus 30 validated ideas. |
| `style/house-style.md` | The written voice, reverse-engineered from the five finished articles. |
| `style/narration-voice.md` | The spoken voice. Different register from the articles — first person, fallible. |

## The daily loop

One hour. Invoke `morning-hour` and it runs the sequence.

```
0:00–0:05   daily-topic     three pitches, pick one
0:05–0:15   validate-idea   lock title + thumbnail — four gates
0:15–0:50   one work block  analysis OR writing OR charts OR VO OR edit
0:50–1:00   ship, or log tomorrow's first action in ideas/wip.md
```

**The one rule: no analysis starts before the title and thumbnail are locked.**

## The skills

| Skill | Does |
|---|---|
| `morning-hour` | Orchestrates the daily hour. Start here. |
| `daily-topic` | Five-minute topic pick from live sports discourse. Three pitches. |
| `validate-idea` | Four gates. Kills bad ideas before they cost twenty hours. |
| `write-article` | Belief-on-trial article in house voice. |
| `write-script` | Article → narrated script with retention structure. |
| `package-video` | Titles, thumbnail spec, description, chapters, pre-publish checklist. |
| `footage-policy` | League-by-league Content ID decision table + deterministic clip checker. |
| `animate` | The Remotion pipeline — charts, title cards, 3D play reconstruction. |

Planned, not yet built: `build-artifact` (markdown → designed HTML).

External skills to install: `npx skills add remotion-dev/skills` for React/Remotion
mechanics, and load the built-in `dataviz` skill before any chart work.

## Skill design principle

Every skill separates four things. This is what makes one-shot output improve over time.

```
SKILL.md      the PROMPT — judgment only
references/   durable STANDARDS — voice, policy tables, specs
scripts/      DETERMINISTIC automation — code, not prose
templates/    CONSISTENCY artifacts — what output is built from
```

**Iterate the references, not the prompt.** When a video underperforms or a draft misses,
the fix goes into a reference file and every future generation inherits it.

## The work so far

Five finished articles, published as Claude artifacts — a hub and four spokes:

- **Against the Book** — the hub. NFL conventional wisdom on trial, 532k+ plays.
- **The Grind** — establish the run. *Mostly myth, one grain of truth.*
- **The Tell** — Andy Reid, the readable genius. *Backwards.*
- **Two-Minute Panic** — timeout discipline. *Names named.*
- **Cold Snap** — icing the kicker. *No signal.*

## Current state

- Late July 2026. US sports ad dead zone runs through August — the right time to build a
  library, not launch into silence.
- Two videos near-ready. Target: 4–5 pieces live before NFL Week 1.
- Cadence: 6–8 minutes every 2–3 weeks. Earn the twelve minutes.
- Animation stack: Remotion. Decision record in `.claude/skills/animate/references/`.
