# This year's play-callers, ranked by predictability. Uses samhoppen current
# play-caller attribution (2025 primary caller per team) joined to career
# predictability + offense.
suppressMessages({library(data.table); library(ggplot2); library(scales)})
setDTthreads(4)
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")
ROOT <- "/Users/nick/stranger9977/nfl-analysis"
cc <- as.data.table(readRDS(file.path(ROOT,"scratch/pred_career.rds")))
pc <- fread(file.path(ROOT,"data/playcallers.csv"))

# primary 2025 caller per team (most weeks), then distinct callers
cur <- pc[season==2025, .N, by=.(team, off_play_caller)]
setorder(cur, team, -N); cur <- cur[, .SD[1], by=team]
callers <- unique(cur$off_play_caller)

d <- cc[off_play_caller %in% callers & n_plays>=1000]
setorder(d, guess_xs); d[, yi := .I]
r_all <- cor(cc$guess_xs, cc$epa_play)
cat("current play-callers ranked:\n")
print(d[order(-guess_xs), .(off_play_caller, guess_xs=round(guess_xs,2), epa=round(epa_play,3))], nrow=40)

lim <- max(abs(d$epa_play))
p <- ggplot(d, aes(guess_xs, yi)) +
  geom_vline(xintercept=0, color=col_baseline, linewidth=.4) +
  annotate("text", x=0, y=nrow(d)+0.9, label="league-average predictability", hjust=.5, vjust=0,
           size=2.7, color=ink_muted, family="mono") +
  geom_segment(aes(x=0, xend=guess_xs, yend=yi), color=col_grid, linewidth=.6) +
  geom_point(aes(fill=epa_play), shape=21, size=4.6, stroke=.5, color=col_surface) +
  geom_text(aes(label=number(epa_play,.01,style_positive="plus")),
            hjust=-0.0, nudge_x=0.12, size=2.9, fontface="bold", color=ink_secondary) +
  scale_fill_gradient2(low=pal_div$high, mid=pal_div$mid, high=pal_div$low, midpoint=0,
                       limits=c(-lim,lim), labels=number_format(.01,style_positive="plus"),
                       name="Offense\nEPA/play") +
  scale_y_continuous(breaks=d$yi, labels=d$off_play_caller, expand=expansion(add=c(.6,1.4))) +
  scale_x_continuous(limits=c(-0.6, 4.1), breaks=0:4,
                     labels=c("league","+1","+2","+3","+4")) +
  labs(title="This year's play-callers, most to least predictable",
       subtitle="Every team's 2025 play-caller, career figures. Further right = a defense guesses your run or pass more reliably than\nit does against an average team. Dot color is offense: the readable names skew blue (good), and Ben Johnson is the outlier.",
       x="Predictability (extra plays out of 100 an optimal guesser calls right, vs league)", y=NULL,
       caption=sprintf("nflverse play-by-play 2015-2025; play-caller attribution from samhoppen/NFL_public. 30 of 32 teams' 2025 callers have 1,000+ career plays (Patullo,\nEngstrand, Grizzard, Hardegree, Rees, Morton-share and first-year HCs excluded). More-predictable-than-league still ties to better offense (r = %+.2f).", r_all)) +
  theme_nfl() + theme(axis.text.y=element_text(size=9, color=ink_secondary),
                      legend.position="right", legend.key.height=unit(20,"pt"))
save_chart(p, "predictability-current", width=10, height=8.2)
cat("\nDONE\n")
