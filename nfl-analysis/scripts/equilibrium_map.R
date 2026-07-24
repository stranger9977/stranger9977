# CHART 1: The equilibrium map — where the run/pass mix is furthest from indifference
library(data.table); library(ggplot2); library(scales)
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")

allr <- readRDS("/tmp/claude-0/-home-user-stranger9977/f03221fa-fab0-55bd-bf7a-5b49b7ec5a63/scratchpad/slice_tab.rds")

# curated exploitable cells (adequate n, clear direction)
pick <- rbind(
  allr[slice=="Open field (own20-opp40)" & bucket=="1st&10"][, lab:="Open field, 1st & 10"],
  allr[slice=="High-lev late (2H,1score,<5min)" & bucket=="down1"][, lab:="Late & close, 1st down"],
  allr[slice=="High-lev late (2H,1score,<5min)" & bucket=="down2"][, lab:="Late & close, 2nd down"],
  allr[slice=="Two-minute offense" & bucket=="down1"][, lab:="Two-minute, 1st down"],
  allr[slice=="Red zone (<=20)" & bucket=="down1"][, lab:="Red zone, 1st down"],
  allr[slice=="Red zone (<=20)" & bucket=="down2"][, lab:="Red zone, 2nd down"],
  allr[slice=="Short yardage 3rd/4th&1-2" & bucket=="down3_1"][, lab:="3rd & 1, anywhere"],
  allr[slice=="Red zone (<=20)" & bucket=="down3"][, lab:="Red zone, 3rd down"],
  allr[slice=="Goal-to-go inside 5" & bucket=="down3"][, lab:="Goal-to-go inside 5, 3rd down"],
  allr[slice=="Short yardage 3rd/4th&1-2" & bucket=="down4_1"][, lab:="4th & 1, anywhere"]
)
pick[, dir := ifelse(gap>0, "Pass is underused", "Run is underused")]
pick[, n_tot := n_pass + n_run]
# cells where the raw pass-minus-run gap is confounded by self-selection:
# teams pass here only in the toughest spots, so the run's edge is overstated.
pick[, confounded := lab %in% c("4th & 1, anywhere", "Goal-to-go inside 5, 3rd down")]
setorder(pick, gap)
pick[, lab := factor(lab, levels=lab)]
pick[, passpct := round(pass_rate*100)]
# recommendation label: does current pass rate lean the wrong way vs the gap?
pick[, note := ifelse(gap>0, paste0("league passes ", passpct, "%"),
                              paste0("league passes ", passpct, "%"))]

print(pick[, .(lab, gap=round(gap,3), ci_lo=round(ci_lo,3), ci_hi=round(ci_hi,3), passpct, n_tot)])

xr <- range(c(pick$ci_lo, pick$ci_hi))
p <- ggplot(pick, aes(x=gap, y=lab, color=dir)) +
  geom_vline(xintercept=0, color=col_baseline, linewidth=0.6) +
  geom_errorbarh(aes(xmin=ci_lo, xmax=ci_hi), height=0, linewidth=0.9, alpha=0.85) +
  geom_point(aes(shape=confounded), size=4.2, fill=col_surface, stroke=1.2) +
  scale_shape_manual(values=c(`FALSE`=19, `TRUE`=21), guide="none") +
  geom_text(aes(label=sprintf("%+.2f%s", gap, ifelse(confounded, "*", ""))),
            vjust=-1.15, size=3.5, fontface="bold", color=ink_primary) +
  geom_text(aes(x=ci_hi, label=note), hjust=-0.12, size=2.9, color=ink_secondary) +
  scale_color_manual(values=c("Pass is underused"=pal_cat[1], "Run is underused"=pal_cat[8]),
                     name=NULL) +
  scale_x_continuous(expand=expansion(mult=c(0.06,0.40)),
                     breaks=seq(-0.5,0.2,0.1),
                     labels=function(x) sprintf("%+.1f", x)) +
  coord_cartesian(clip="off") +
  annotate("text", x=0.12, y=10.7, label="PASS gains more  >>", color=pal_cat[1],
           size=3.2, fontface="bold", hjust=0) +
  annotate("text", x=-0.15, y=10.7, label="<<  RUN gains more", color=pal_cat[8],
           size=3.2, fontface="bold", hjust=1) +
  labs(
    title="Pass more on early downs; run more at the goal line",
    subtitle="Pass-minus-run EPA/play by game state (95% CI). Positive = passing beats running; the % is how often the league actually passes.\nThe mix flips inside the 5: on 3rd-and-goal, runs beat passes by 0.21 EPA yet coaches pass 68% of the time.",
    x="Called-pass EPA  minus  called-run EPA (per play)", y=NULL,
    caption="pbp_slim 2015-2025. Scrambles=called passes (qb_dropback); kneels/spikes/no-plays out; vegas_wp 5-95%. Each cell n>1,200.\nGaps are average (not marginal) EPA differences.\n* hollow point = raw gap; passing here is self-selected, overstating the run's counterfactual value."
  ) +
  theme_nfl() +
  theme(legend.position="top", legend.justification="left",
        panel.grid.major.y=element_blank(),
        plot.margin=margin(16,24,12,16))

save_chart(p, "equilibrium_map", width=11, height=7)
