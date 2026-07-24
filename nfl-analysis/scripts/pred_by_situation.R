# =====================================================================
# WHERE PREDICTABILITY PAYS, by situation slice
# Per caller-season, predictability (guess_xs, EB-shrunk, same cells as
# the headline) computed SEPARATELY within 5 situations, each correlated
# with the caller-season's offensive EPA/play. Bootstrap 95% CIs.
# Positive r = committing to a tendency goes with better offense.
#
# This is a CORRELATIONAL gradient, not a causal claim. To guard against
# the obvious confound (good QBs make everything work), the early-down
# link is re-checked net of passer quality:
#   - QB proxy = caller-season mean CPOE (completion % over expected).
#   - PARTIAL r(early guess_xs, EPA | CPOE) = +0.25  (raw +0.376).
#   - Std. regression z_EPA ~ z_earlyGuess + z_CPOE + z_nPlays:
#       early-down coef beta = +0.16 SD, t=4.44, p<0.001  -> survives.
#   Reproduced from scratch/pred_plays.rds + data/pbp_slim.rds (cpoe),
#   377 caller-seasons >=300 plays, slice floor >=40. (scratchpad/partial.R)
#
# Named exemplars (elite offense AND top-of-league early-down predictable,
# career, >=800 early plays; from pred_career.rds + early-slice guess_xs):
#   Andy Reid  EPA +.129 / early guess_xs 4.18
#   Joe Brady  EPA +.084 / early guess_xs 4.21   (league median ~2.0)
#   (Ben Johnson is the elite counter-example: +.089 EPA, only 0.44.)
# =====================================================================
suppressMessages(library(data.table)); library(ggplot2)
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")
ROOT <- nfl_root

res <- as.data.table(readRDS(file.path(ROOT,"scratch/slice_coef.rds")))

# order top->bottom by r (most "predictability pays" on top)
setorder(res, r)
res[, label := factor(label, levels=label)]

# color: diverging by r, but grey out non-significant (CI crosses 0)
ramp <- colorRamp(c(pal_div$mid, pal_div$high))     # neutral -> red (all r>=~0)
res[, fill := {
  t <- pmin(pmax(r/0.40,0),1)                        # scale to strongest slice
  rgbv <- ramp(t); rgb(rgbv[,1],rgbv[,2],rgbv[,3], maxColorValue=255)
}]
res[r<0, fill := pal_div$low]                        # any negative -> blue
res[p_signif==FALSE, fill := col_baseline]           # null slices -> grey
res[, txtcol := ifelse(p_signif, ink_primary, ink_muted)]

# value labels
res[, rlab  := sprintf("r = %+.2f", r)]
res[, sublab:= sprintf("95%% CI [%+.2f, %+.2f]  ·  n=%d  ·  ~%d plays/slice",
                       lo, hi, n_cs, med_plays)]
res[p_signif==FALSE, rlab := sprintf("r = %+.2f   (n.s.)", r)]

# per-row third line: exemplars for the early row, attenuation for the nulls
res[, note := ""]
res[slice=="early",
    note := "elite & predictable: Andy Reid (+.13 EPA), Joe Brady (+.08)"]
res[p_signif==FALSE,
    note := "underpowered (~49-119 plays): no detected effect, not proof surprise is neutral"]
res[, notecol := ifelse(slice=="early", ink_secondary, ink_muted)]

LX  <- 0.52                        # left edge of the right-hand text column
xmin <- min(res$lo)-0.05; xmax <- 1.42   # extra right whitespace hosts the text column

p <- ggplot(res, aes(y=label)) +
  geom_vline(xintercept=0, color=ink_secondary, linewidth=0.5) +
  # ---- robustness banner (top): early-down link isn't just good QBs ----
  annotate("text", x=xmin, y=6.28, hjust=0, vjust=1, size=2.95, color=ink_secondary,
           lineheight=1.0, fontface="plain",
           label=paste0(
             "Not just elite QBs. The early-down link survives a passer-quality control: partial r = +0.25 net of CPOE\n",
             "(completion % over expected). Early-down predictability adds to EPA independently of QB accuracy and\n",
             "volume (standardized β = +0.16 SD, p < 0.001). A correlation, not proof of cause.")) +
  annotate("text", x=0, y=5.58, label="← surprise pays        predictability pays →",
           color=ink_muted, size=3.1, fontface="italic", vjust=0, hjust=0.42) +
  geom_segment(aes(x=0, xend=r, yend=label, color=I(fill)), linewidth=1.1) +
  geom_errorbarh(aes(xmin=lo, xmax=hi, color=I(fill)), height=0.16, linewidth=0.9) +
  geom_point(aes(x=r, color=I(fill)), size=5) +
  geom_text(aes(x=LX, label=rlab,   color=I(txtcol)), hjust=0, nudge_y=0.17, fontface="bold", size=3.5) +
  geom_text(aes(x=LX, label=sublab, color=I(ink_muted)), hjust=0, nudge_y=-0.04, size=2.7) +
  geom_text(aes(x=LX, label=note,   color=I(notecol)),
            hjust=0, nudge_y=-0.26, size=2.6, fontface="italic") +
  scale_x_continuous(limits=c(xmin,xmax),
                     breaks=seq(-0.1,0.4,0.1),
                     labels=function(z) sprintf("%+.1f", z)) +
  scale_y_discrete(expand=expansion(add=c(0.6,1.7))) +
  labs(
    title="Predictability pays most on early downs. Surprise pays nowhere",
    subtitle="Within-situation correlation of a play-caller's predictability with its offense's EPA/play. A gradient, not a switch:\nthe payoff is largest early, smaller on obvious passing downs, and undetectable in thin late/short slices. Predictability =\nextra plays per 100 a defense guesses right vs league (EB-shrunk). Positive = more predictable goes with better offense.",
    x="correlation of predictability with offensive EPA/play  (95% bootstrap CI)",
    y=NULL,
    caption="Called pass/run plays, WP 5-95%, 2015-2025 (305,827 plays; 377 caller-seasons, >=300 season plays, slice floor >=40).\nSame situation cells + K=15 EB shrinkage as the headline build. Grey = 95% bootstrap CI crosses zero (no detected effect); 3,000 reps.\nRobustness: partial r and standardized regression control for passer CPOE (QB quality) and play volume; early-down coef survives."
  ) +
  theme_nfl() +
  theme(panel.grid.major.y=element_blank(),
        axis.text.y=element_text(color=ink_primary, size=11.5, face="bold", hjust=0),
        plot.caption=element_text(margin=margin(t=10)))

save_chart(p, "pred_by_situation", width=11, height=7.0)
