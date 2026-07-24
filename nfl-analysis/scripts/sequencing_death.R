# CHART 2: Sequence memory test — does the previous call change the next play's value?
library(data.table); library(ggplot2); library(scales)
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")

pbp <- as.data.table(readRDS("/home/user/stranger9977/nfl-analysis/data/pbp_slim.rds"))
pbp <- pbp[!is.na(vegas_wp) & vegas_wp>=0.05 & vegas_wp<=0.95]
pbp <- pbp[qb_kneel!=1 & qb_spike!=1 & play_type!="no_play" & !is.na(play_type)]
pbp[, called_pass := as.integer(qb_dropback==1)]
pbp[, called_run  := as.integer(rush==1 & qb_dropback!=1)]
pbp <- pbp[(called_pass==1|called_run==1) & !is.na(epa)]
pbp[, calltype := ifelse(called_pass==1,"pass","run")]
setorder(pbp, game_id, play_id)
pbp[, prev_call := shift(calltype), by=.(game_id, drive)]
pbp <- pbp[!is.na(prev_call)]

# For each STATE, compute next-play EPA of a called PASS after prev-run vs prev-pass,
# and the after-run minus after-pass difference with 95% CI (the "establish the run" effect).
mk <- function(dt, label){
  a <- dt[prev_call=="run"];  b <- dt[prev_call=="pass"]
  d <- mean(a$epa)-mean(b$epa)
  se <- sqrt(var(a$epa)/nrow(a)+var(b$epa)/nrow(b))
  data.table(state=label, epa_after_run=mean(a$epa), epa_after_pass=mean(b$epa),
             diff=d, lo=d-1.96*se, hi=d+1.96*se, n_run=nrow(a), n_pass=nrow(b))
}
seqp <- pbp[calltype=="pass"]
tab <- rbind(
  mk(seqp[down==1 & ydstogo==10], "1st & 10"),
  mk(seqp[down==2 & ydstogo>=8],  "2nd & long (8+)"),
  mk(seqp[down==2 & ydstogo<=3],  "2nd & short (1-3)"),
  mk(seqp[yardline_100<=20 & down %in% 1:2], "Red zone, early down"),
  mk(seqp[yardline_100>=40 & yardline_100<=80 & down %in% 1:2], "Open field, early down")
)
tab[, n := n_run+n_pass]
setorder(tab, diff)
tab[, state := factor(state, levels=state)]
print(tab[, .(state, epa_after_run=round(epa_after_run,3), epa_after_pass=round(epa_after_pass,3),
              diff=round(diff,3), lo=round(lo,3), hi=round(hi,3), n)])

p <- ggplot(tab, aes(x=diff, y=state)) +
  annotate("rect", xmin=-0.05, xmax=0.05, ymin=-Inf, ymax=Inf,
           fill=ink_muted, alpha=0.12) +
  geom_vline(xintercept=0, color=col_baseline, linewidth=0.7) +
  geom_errorbarh(aes(xmin=lo, xmax=hi), height=0, linewidth=0.9, color=pal_cat[1]) +
  geom_point(size=4.2, color=pal_cat[1]) +
  geom_text(aes(label=sprintf("%+.3f", diff)), vjust=-1.25, size=3.4,
            fontface="bold", color=ink_primary) +
  annotate("text", x=0, y=5.62, label="\"negligible\" zone  |effect| < 0.05 EPA",
           color=ink_secondary, size=3.1, fontface="italic") +
  scale_x_continuous(breaks=seq(-0.08,0.08,0.02), expand=expansion(mult=c(0.12,0.12)),
                     labels=function(x) sprintf("%+.2f", x)) +
  coord_cartesian(clip="off") +
  labs(
    title="\"Establish the run\" is a myth: a prior run doesn't set up the next pass",
    subtitle="Extra EPA a called pass gains when the PREVIOUS snap was a run vs a pass, same drive & state bucket (95% CI).\nEvery point sits inside the negligible band -- on 1st-and-10 it is -0.015 EPA and statistically zero.",
    x="Pass EPA after a run  minus  pass EPA after a pass (per play)", y=NULL,
    caption="pbp_slim 2015-2025, consecutive plays within a drive. Scrambles=called passes; kneels/spikes/no-plays out; vegas_wp 5-95%. n>4,500 pass plays/cell."
  ) +
  theme_nfl() +
  theme(panel.grid.major.y=element_blank(),
        plot.margin=margin(16,20,12,16))

save_chart(p, "sequencing_death", width=11, height=6.5)
