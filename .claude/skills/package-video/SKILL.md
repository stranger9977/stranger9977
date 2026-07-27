---
name: package-video
description: Produce the final publish package for a video — title variants, thumbnail spec, description, chapters, tags, pinned comment, and the pre-publish checklist. Use as the last step before uploading. Triggers on "package this video", "write the description", "make the thumbnail", "ready to publish".
---

# Package the video

The last step before upload. The title and thumbnail were locked back in `validate-idea`
— this skill produces the final assets and everything else the upload needs.

If the locked title and thumbnail no longer fit what the video became, say so explicitly
rather than quietly changing them. That mismatch is worth noticing: it usually means the
finding moved during analysis, which is fine, but the packaging has to move with it.

## Title

Deliver the locked title plus two alternates for Test & Compare.

- Payload in the **first 45–50 characters**.
- Never promise something the video doesn't deliver. A title that oversells shows up
  immediately as a retention cliff, and YouTube's ranking has been shifting weight toward
  measured viewer satisfaction rather than raw clicks.

## Thumbnail spec

Write the spec precisely enough to build without further decisions.

```
Base:       [the chart, described — which series, which axes, what shape]
Crop:       [what's visible at 320px wide]
Text:       "[0-3 words]" · [font, size, position]
Palette:    [one dominant hue + accent]
Contrast:   [what makes it legible at 10 feet on a TV]
```

Remember the format's advantage: **the chart is the face.** One bold, weird, legible data
shape. Never repeat the title in the thumbnail text.

## Description

```
[One or two sentences — the reversal, stated plainly. This is what shows above the fold
and what search reads.]

Read the full piece, with all the charts: [artifact URL]
Get new pieces by email: [newsletter URL]

CHAPTERS
0:00 [hook title, not a label]
...

METHOD
Data: [source, seasons, sample]
Controls: [what was held fixed]
Caveat: [the honest limitation — correlation not cause, observational, etc.]

Built in R with nflfastR / nflreadr. Charts by me.
```

The METHOD block is not optional. It's the same discipline as the article's methods
footer, it's what makes a skeptical viewer trust the video, and it's what keeps a strong
headline defensible when you're publishing under your own name as a working data
scientist.

## Chapters

Chapter titles are **hooks, not labels**. "Nobody breaks" beats "Section 3."

One honest caveat: chapters are a genuine trade-off, and no A/B evidence was found either
way. They raise discoverability — Google surfaces them as Key Moments, driving impressions
into mid-video segments — but **every timestamp is a potential exit point**, and
search-sourced viewers who land mid-video skip your setup entirely. Worth asking your
YouTube manager friend, who'll have a real opinion.

## Pinned comment

One line, and make it a question that invites the disagreement the piece will provoke.
The comments on a belief-on-trial piece are half the value — people who hold the belief
will show up, and engaging them well is how a channel builds a real audience rather than
a passive one.

## Pre-publish checklist

- [ ] Audio normalized to **−14 LUFS integrated**
- [ ] Every number on screen matches the article, and both match the analysis output
- [ ] No stat appears that you did not personally compute
- [ ] The methods caveat is in the video, not only the description
- [ ] Thumbnail legible at 320px and from ten feet
- [ ] Title payload inside 50 characters
- [ ] Chapters timestamped and named as hooks
- [ ] Newsletter link in the description, first two lines
- [ ] Article artifact URL live and cross-linked back to the video
- [ ] End screen points to the next piece in the series, not to a generic subscribe
- [ ] **No game footage.** Charts, stills you have rights to, and your own graphics only.

That last box is the one that protects the whole business. Your Content ID exposure is
effectively zero because you use no broadcast footage — see `channel/strategy/00-strategy.md`
§3. The temptation to drop in a highlight will be constant. Don't.

## After publishing

Log in `channel/ideas/wip.md`: publish date, title, and the thumbnail variant used, so
the weekly instrumentation pass has something to compare against.
