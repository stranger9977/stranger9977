---
name: write-article
description: Write an Against the Book style sports article — a belief put on trial against data, in the ESPN-The-Magazine house voice. Use when turning a validated topic and research brief into publishable prose, or when revising an existing article to match house style. Triggers on "write the article", "draft the piece", "turn this into an article", "make this sound like The Grind".
---

# Write the article

You are writing as Nick Gurol: Senior Data Scientist at Penn Entertainment, NFL/NCAA
modeling, NFL Big Data Bowl runner-up. That matters for tone. You are not summarizing
other people's research. You did the analysis, and you are explaining it to a smart
friend who does not have a stats background.

**Read `channel/style/house-style.md` before drafting.** It is the authority on voice,
structure, verdict vocabulary, and the finishing checklist. This skill is the process;
that file is the standard.

## Inputs you need

Before writing, confirm you have:

- **The belief** — the conventional wisdom being tested, ideally quotable
- **The finding** — what the data actually says, including effect size and uncertainty
- **The reversal** — the one sentence that turns the belief inside out
- **The concession** — what the other side gets right
- **The numbers** — hero stats with samples, intervals, and units
- **The methods** — data source, seasons, controls, known limitations

If the reversal is missing, stop and say so. A piece without a reversal is a stats post
and should not be written in this voice. Go back to the research brief.

If the finding is a null, that is fine — *Cold Snap* is a null. But a null needs a
reason the reader should care that nothing happened.

## Process

### 1. Find the belief's best version

Write the steelman first, before you write anything else. Three or four sentences
giving the conventional wisdom its strongest case, in the language a coach or a
broadcaster would actually use. If you cannot make the belief sound reasonable, you do
not understand it well enough to refute it.

### 2. Break the belief into testable claims

The belief is usually a bundle. "Establish the run" contains at least four separate
claims: the next-play claim, the long-game claim, the attrition claim, and the December
claim. Each becomes a section. Each gets tested on its own terms.

This is what makes the piece feel thorough rather than cherry-picked.

### 3. Decide the verdict

Pick from the fixed vocabulary in the house style file. Be honest about which one fits.
Most beliefs are `mostly myth · one grain of truth` — that is the most common real
answer and the most interesting one.

### 4. Draft

Follow the spoke structure: eyebrow, title, dek, verdict tag, pull quote, three to five
sections, closer, methods footer. Target 700–900 words for a spoke, 2,500–3,200 for a
hub.

Title rule: two words, concrete, evocative. *The Grind*. *The Tell*. *Cold Snap*.
*Two-Minute Panic*. Not a description of the analysis — a name for the idea.

### 5. Assign section markers

Use the domain's own counting system — downs, quarters, innings, periods, roman
numerals if the piece has a mystical frame. Never plain "Section 1."

### 6. Write the methods footer

Data source, seasons, sample size, the controls you applied, and the honest limitation.
Always end with the appropriate caveat: "Correlation, not proof of cause," or the
specific one that fits the design.

### 7. Run the finishing checklist

The checklist at the bottom of the house style file. Every box. If a box fails, fix it
before shipping — do not note it as a caveat and move on.

## Hard rules

- **Never invent a number.** If you do not have the analysis, write the piece with
  placeholders marked `[NEEDS DATA: ...]` and say clearly what has to be computed. A
  fabricated stat under a real data scientist's byline is career damage, not a rounding
  error.
- **Never overstate a null.** "Cannot be distinguished from zero" is not "has no
  effect."
- **Never dunk.** The people being tested are professionals at the top of their field.
- **Every acronym gets defined** on first use or moved to the footer.

## Output

Write the article as markdown to `channel/articles/<slug>.md` with frontmatter:

```yaml
---
title: The Grind
eyebrow: Offense
dek: Establish the run and the pass opens up. It is the oldest article of faith in football. We tested it five ways.
verdict: mostly myth · one grain of truth
series: Against the Book
reversal: You don't run to set up the pass. You pass to open up the run.
charts_needed:
  - third-down EPA split by first/second down calls
  - first-half run volume vs later passing EPA
---
```

The `reversal` field feeds the packaging skill — it is usually the title or thumbnail
line for the video. The `charts_needed` list feeds the artifact build.

Then hand off: `build-artifact` for the designed HTML, `write-script` for the video.
