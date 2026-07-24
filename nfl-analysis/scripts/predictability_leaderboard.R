# Chart 2: Predictability leaderboard, top-10 most vs bottom-10 least
# conditionally predictable career play-callers, colored by offense quality.
suppressMessages({library(data.table); library(ggplot2); library(scales)})
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")
OUT <- "/tmp/claude-0/-home-user-stranger9977/f03221fa-fab0-55bd-bf7a-5b49b7ec5a63/scratchpad"
career <- readRDS(file.path(OUT,"pred_career.rds"))

setorder(career, -guess_xs)
top <- career[1:10]; bot <- career[(.N-9):.N]
lb <- rbind(top, bot)
lb[, grp := ifelse(off_play_caller %in% top$off_play_caller,
                   "10 MOST predictable","10 LEAST predictable")]
lb[, good := ifelse(epa_play>=0, "Above-avg offense (EPA/play > 0)",
                                 "Below-avg offense (EPA/play < 0)")]
lb[, lab := sprintf("%s  (%s%.0f EPA/100, n=%s)", off_play_caller,
                    ifelse(epa_play>=0,"+",""), epa_play*100, prettyNum(n_plays,big.mark=","))]
setorder(lb, guess_xs)
lb[, lab := factor(lab, levels=lab)]

p <- ggplot(lb, aes(guess_xs, lab, color=good)) +
  geom_segment(aes(x=0, xend=guess_xs, yend=lab), linewidth=0.5, color=col_baseline) +
  geom_vline(xintercept=0, color=col_baseline, linewidth=0.4) +
  geom_point(size=4.4) +
  geom_text(aes(label=sprintf("%+.1f", guess_xs)),
            hjust=ifelse(lb$guess_xs>=0,-0.35,1.35), size=3.0,
            color=ink_secondary, fontface="bold") +
  scale_color_manual(values=c("Above-avg offense (EPA/play > 0)"=pal_cat[1],
                              "Below-avg offense (EPA/play < 0)"=pal_cat[2]),
                     name=NULL) +
  scale_x_continuous(limits=c(-1.2,4.1), breaks=seq(0,4,1),
                     labels=function(x) ifelse(x>0,paste0("+",x),as.character(x))) +
  labs(
    title="Unpredictable play-callers are mostly just bad ones",
    subtitle="Career conditional predictability: extra pass/run calls an optimal situational guesser gets right per 100 plays, vs the\nleague in the same down/distance/field/score/half cells. The most-predictable callers are elite offenses; the least-predictable\nskew below-average — Ben Johnson is the lone exception who is genuinely hard to read AND good.",
    x="Conditional predictability  (extra correct guesses per 100 plays, vs league)",
    y=NULL,
    caption="nflverse play-by-play 2015-2025. Called plays only: qb_dropback or designed rush; kneels/spikes & vegas_wp<5% / >95% garbage time excluded. Cell\npass rates empirical-Bayes shrunk toward the league rate (k=15) to de-bias small-sample entropy. Play-caller from nflverse playcallers.csv. Career callers with\n≥1,000 called plays (n=80). r(predictability, EPA/play)=+0.35 career, +0.40 per caller-season; next-season r=+0.20 — predictable callers stay better."
  ) +
  theme_nfl() +
  theme(legend.position=c(0.72,0.18),
        legend.background=element_rect(fill=col_surface,color=col_grid),
        panel.grid.major.y=element_blank(),
        plot.caption.position="plot",
        axis.text.y=element_text(color=ink_primary, size=10.5))
save_chart(p, "predictability_leaderboard", width=11, height=8)
