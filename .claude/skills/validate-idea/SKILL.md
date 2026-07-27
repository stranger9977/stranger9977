---
name: validate-idea
description: Lock the title and thumbnail for a video BEFORE any analysis or production begins, and kill ideas that can't carry a piece. Use immediately after picking the day's topic. Triggers on "validate this idea", "lock the title", "is this a good video", "package this before I build it".
---

# Validate the idea before you build it

The most expensive mistake available to you is spending twenty hours of analysis on an
idea that was never going to work. This skill costs ten minutes and prevents that.

**The rule: no analysis begins until the title and thumbnail are locked.**

Paddy Galloway's version — *"Always plan your title and thumbnail before recording.
Everyone knows this, few do this."* MrBeast's production document says the same thing
structurally: every video's creative process starts with the title and thumbnail, and
everything downstream is defined against them.

The reported split is that small creators spend roughly 95% of their time on production
and 5% on ideation and packaging, while top creators spend around 30% on ideation and
packaging. That gap is the whole game.

## The four gates

An idea has to clear all four. If it fails one, kill it and go back to `daily-topic`.
Killing an idea here is a win, not a failure.

### Gate 1 — The reversal

Write the reversal in one sentence a person could repeat at a bar.

> "You don't run to set up the pass. You pass to open up the run."
> "The best play-caller in football is also the easiest one to read."

If you cannot write this sentence, **there is no piece.** A finding without a reversal is
a stats post. Stop here.

A null counts as a reversal if the null is surprising — *Cold Snap* is an entire piece
about nothing happening, and it works because everyone believes the opposite.

### Gate 2 — The title

Write five. Then pick one.

- Two words where possible, matching the series convention: *The Grind*, *The Tell*,
  *Cold Snap*, *Two-Minute Panic*.
- The payload lands in the **first 45–50 characters** — mobile and TV truncate.
- Name-led (the search anchor), number-led (the curiosity gap), or contrarian.
- **Contrarian only if you can actually prove it.** An argument title you can't deliver
  destroys retention worse than a boring one.

Test: would *you* click it in a feed, next to everything else you follow?

### Gate 3 — The thumbnail

Describe it in one sentence. If you can't, the idea is too abstract.

Your format's advantage: **the chart is the face.** You don't have a shocked human
expression to sell the click, so you need one bold, weird, legible data shape doing that
job. A visibly strange graph is the faceless equivalent.

- 0–3 words, huge. **Never repeat the title.**
- One dominant hue, high contrast.
- Legible from ten feet on a TV, and at thumbnail size on a phone.
- No red arrows or circles — reads as low-effort and fights the magazine positioning.

### Gate 4 — The data actually exists

Name the dataset and the specific columns. `nflfastR` play-by-play, participation
charting, FTN, Next Gen Stats, the portal trackers.

Be honest about whether the analysis is a two-hour job or a two-week job. Say so now,
before you're eight hours in.

If the data doesn't exist or the finding requires charting you don't have access to,
**bank the idea** in `channel/ideas/backlog.md` and pick something else.

## Output

```
## LOCKED — [Title]

**Reversal:** [one sentence]
**Title:** [final] ([N] chars)
**Thumbnail:** [one sentence] · Text: "[0-3 words]"
**Data:** [source, columns, and the honest time estimate]
**Verdict prediction:** [which verdict tag you expect — and note that if the
                        data disagrees, the data wins and the piece changes]
**Kill criteria:** [what finding would mean you abandon this]
```

That last field matters. Decide in advance what result would make you walk away, so you
don't talk yourself into publishing a weak finding because you've already spent the
hours. This is the same discipline as the *Cold Snap* Pete Carroll section — pre-commit,
then check.

Hand off to the analysis, then `write-article`.
