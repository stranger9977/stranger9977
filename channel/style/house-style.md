# House Style

This is the voice. It was reverse-engineered from *Against the Book* — the hub plus
*The Grind*, *The Tell*, *Two-Minute Panic*, and *Cold Snap*. Every article and every
script has to sound like it came from the same person who wrote those. If a draft
doesn't pass the checklist at the bottom, it isn't finished.

The target feeling is ESPN The Magazine: a smart friend who did the work, talking to
you like an adult, with design that respects your attention. Not a stats account. Not
a hot-take show.

---

## The core move

Every piece is a **belief on trial**.

1. State the belief in the words a real person actually uses — ideally a quote.
2. Steelman it. Give it a genuine hearing.
3. Test it against data, one angle at a time.
4. Deliver a verdict, including "we couldn't tell."
5. Find the reversal — the part that turns the idea inside out.

The reversal is the payload. *The Grind* isn't "running doesn't work," it's **"you pass
to open up the run."** *The Tell* isn't "predictability is fine," it's **"the best
play-caller in football is the easiest one to read."** Without a reversal, you have a
stats post, not a story.

## Steelman before you swing

> "Every run-first coach makes some version of that case, and it deserves a real
> hearing, not a stat dunk."

That line is the whole ethic. The audience includes people who believe the thing. If
they feel dunked on in the first thirty seconds, they leave. Give the belief its best
version — the sequencing argument, the attrition argument, the December argument — and
answer each on its merits. You earn the reversal by taking the other side seriously
first.

Corollary: **let the other side win something.** *The Grind* gives the run-first coach
December. That single concession buys credibility for everything else in the piece.

## Verdicts are a fixed vocabulary

Every piece and every section carries a verdict tag. Keep them short and honest:

- `mostly myth · one grain of truth`
- `backwards`
- `no signal`
- `names named`

"No signal" is a real verdict and gets equal billing. From the methods footer:

> "A null with a tight interval is reported as a null, not a discovery."

Never inflate a null into a finding. Never bury one either — *Cold Snap* is an entire
piece about nothing happening, and it works because the nothing is the point.

## Numbers are characters

A number gets a callout when it carries the argument, not when it's available. One
hero number per section, maximum.

- Give it a unit and a plain-English translation: `−2.9 pts` → "about three fewer
  points of make probability."
- Put uncertainty in the open: "the confidence interval runs straight through zero."
- Report sample size where a reader would be right to be suspicious: `n = 666 to 2,549
  per group`, `4 of 61`, `3 of 8 made`.
- Round to the precision the finding can actually support.

## Name names

Andy Reid. Norv Turner. Pete Carroll. Mike Martz. Abstract findings don't travel;
people do. The Reid twist in *Two-Minute Panic* — roasted for clock management for two
decades, and actually the most reliable timeout manager of his generation — is the most
shareable thing in the series precisely because it is about a person the audience
already has an opinion about.

Be fair when you name someone. *Cold Snap* names Pete Carroll and then spends a whole
section arguing he is **not** an outlier, because that is what the evidence says.

## Show your own homework, including the traps

The Carroll section is a lesson in multiple comparisons disguised as sports writing:
screen twenty-one coaches, one pops out, look closer, it dissolves. Do this whenever
you can. It is the strongest possible signal that the analysis is honest, and it is the
thing no competitor will copy because it takes real work.

> "He is not the exception to the rule. He is the reason you have to check."

## Sentence-level rules

- **Short declaratives.** "Nobody breaks." "The joke has it backwards." "Nobody owns
  the ice."
- **Second person for the setup.** "Picture yourself as the defense." "You call pass.
  How often are you right?" It turns a chart into a decision the reader is making.
- **Plain words over jargon.** "Expected points" beats "EPA" in the body. Define the
  acronym once, in the footer.
- **No hedge stacking.** One hedge per claim. "It is not that it definitely does
  nothing. It is that if it does something, a quarter century of the best-recorded
  league in sports has not been enough to prove it." That is one careful thought, not
  four hedges.
- **Kill throat-clearing.** No "In this article we will explore." Open on the belief.
- **Contractions are fine in the body, rare in the verdict lines.** Verdicts read
  better formal and clipped.

## Structure of a spoke piece

Roughly 700–900 words. Tight. The charts carry the weight.

```
Eyebrow            Offense / Play-calling / Special teams / Game management
Title              Two words, concrete, evocative — The Grind, The Tell, Cold Snap
Dek                One sentence stating the belief and that it was tested
Verdict tag        The fixed vocabulary above
Pull quote         The belief in a real person's voice, attributed loosely
                   ("Every run-first coach, some version of it")
Sections (3–5)     Each: marker → headline → setup → the test → the number → what it means
Closer             "The verdict" — restate the reversal, concede what's true
Methods footer     Data source, years, sample, controls, and the honest caveat
```

The hub piece is the same spine, longer, with each spoke compressed into one section
and a closing "thread" that states what the findings have in common.

## Section markers give the piece a spine

Use the domain's own counting system as the section marker. It costs nothing and makes
the piece feel authored:

- *The Grind*: `1st`, `2nd`, `3rd`, `4th`, `4th & 1` — downs
- *Two-Minute Panic*: `01`, `02`, `03` with a scoreboard strip
- *The Tell*: tarot-style roman numerals, because the piece is about reading the future

## The methods footer is not optional

Every piece ends with data source, seasons, sample size, controls, and the limits of
the claim. It is short, it is monospace, and it always includes the honest caveat:

> "Correlation, not proof of cause."
> "Observational, so coaches may still ice on cues we cannot measure."

This footer is why a skeptical reader trusts the rest. It also protects you: you are a
working data scientist publishing under your own name, and the footer is what keeps a
strong headline defensible.

## Design principles

Each piece gets its **own visual identity** driven by its subject, while the series
stays recognizable through structure, typography discipline, and the verdict system.

- *The Grind* — worn field chalk, clay rust, heavy condensed type. Trench warfare.
- *The Tell* — midnight indigo, antique gold, high-contrast serif, arcana card. Fortune teller.
- *Two-Minute Panic* — stadium charcoal, alarm amber, seven-segment clock numerals. Scoreboard.
- *Cold Snap* — glacier white, ice cyan, geometric sans, hairline rules. Lab report, because the finding is a null.

Rules that hold across all of them:

- Mobile-first, single column, ~640–660px measure.
- Serif body (Iowan Old Style / Charter / Georgia), monospace for labels and captions,
  a distinctive display face for headlines.
- Tabular numerals everywhere a number appears in a row or chart.
- Charts are tap-to-enlarge with a lightbox. Captions state the sample.
- Light and dark both styled, unless the piece deliberately commits to one world
  (*The Tell* and *Two-Minute Panic* are always dark, and that is a choice, not an oversight).

## What this voice is not

- Not a hot take. The verdict comes from the data, not from the pose.
- Not a stats dump. If a number doesn't advance the argument, cut it.
- Not neutral-to-the-point-of-boring. "Icing the kicker is the most-televised piece of
  strategy in football that does not appear to do anything" is a real sentence with a
  real edge.
- Not condescending to the coach. The people being tested are professionals. The
  finding is that a belief is wrong, not that the believers are stupid.

---

## Finishing checklist

Run this before anything ships.

- [ ] The belief is stated in a real person's words, up top.
- [ ] The steelman is genuine, and the other side wins at least one point.
- [ ] There is a reversal, and it is stated in one sentence a person could repeat at a bar.
- [ ] Verdict tag comes from the fixed vocabulary.
- [ ] One hero number per section, with a unit and a plain-English gloss.
- [ ] Uncertainty is visible — interval, sample size, or an explicit "we can't tell."
- [ ] At least one named person the audience already has an opinion about.
- [ ] Jargon defined on first use, or moved to the footer.
- [ ] Methods footer present, with source, seasons, controls, and the caveat.
- [ ] Read aloud: no sentence makes you run out of breath.
- [ ] A reader who disagrees with the conclusion would still say it was fair.
