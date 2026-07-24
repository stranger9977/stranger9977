# Chart 1: Conditional predictability vs offensive EPA/play (career, 2015-2025)
suppressMessages({library(data.table); library(ggplot2); library(scales)})
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")
OUT <- "/tmp/claude-0/-home-user-stranger9977/f03221fa-fab0-55bd-bf7a-5b49b7ec5a63/scratchpad"
career <- readRDS(file.path(OUT,"pred_career.rds"))

r <- cor(career$guess_xs, career$epa_play)
career[, active := last_season>=2024]

# callers to label, with manual label placement tweaks
lab <- c("Andy Reid","Joe Brady","Todd Monken","Kliff Kingsbury","Shane Steichen",
         "Zac Taylor","Matt LaFleur","Kyle Shanahan","Sean McVay","Sean Payton",
         "Josh McDaniels","Kevin O'Connell","Ben Johnson","Chip Kelly","Adam Gase",
         "Luke Getsy","Nathaniel Hackett","Bill Lazor","Byron Leftwich")
career[, lb := ifelse(off_play_caller %in% lab, off_play_caller, NA)]
# nudge directions per caller to avoid collisions
nud <- fread(text="name,dx,dy,hj
Andy Reid,0.06,0.005,0
Joe Brady,0.06,0.000,0
Todd Monken,0.06,0.004,0
Kliff Kingsbury,0.06,-0.006,0
Shane Steichen,0.00,-0.011,0.5
Zac Taylor,0.00,0.012,0.5
Matt LaFleur,0.06,0.003,0
Kyle Shanahan,-0.06,0.010,1
Sean McVay,0.06,-0.003,0
Sean Payton,-0.06,-0.008,1
Josh McDaniels,0.06,0.004,0
Kevin O'Connell,-0.06,-0.003,1
Ben Johnson,0.06,0.004,0
Chip Kelly,0.06,0.000,0
Adam Gase,0.06,0.004,0
Luke Getsy,0.06,-0.004,0
Nathaniel Hackett,0.06,0.004,0
Bill Lazor,-0.06,0.004,1
Byron Leftwich,0.06,-0.005,0")
career <- merge(career, nud, by.x="off_play_caller", by.y="name", all.x=TRUE)

p <- ggplot(career, aes(guess_xs, epa_play)) +
  geom_hline(yintercept=0, color=col_baseline, linewidth=0.4) +
  geom_vline(xintercept=0, color=col_baseline, linewidth=0.4, linetype="22") +
  geom_smooth(method="lm", se=TRUE, color=ink_secondary, fill=col_grid,
              linewidth=0.7, alpha=0.5) +
  geom_point(aes(color=active, size=n_plays), alpha=0.85) +
  geom_text(aes(x=guess_xs+dx, y=epa_play+dy, label=lb, hjust=hj),
            size=3.05, color=ink_primary, fontface="bold", na.rm=TRUE,
            lineheight=0.85) +
  scale_color_manual(values=c(`TRUE`=pal_cat[1], `FALSE`=ink_muted),
                     labels=c(`TRUE`="Active 2024-25",`FALSE`="Pre-2024"),
                     name=NULL) +
  scale_size_continuous(range=c(1.8,6), guide="none") +
  scale_x_continuous(breaks=seq(-0.5,3.5,0.5), limits=c(-0.65,4.05),
                     labels=function(x) ifelse(x>0,paste0("+",x),as.character(x))) +
  scale_y_continuous(labels=function(y) sprintf("%+.2f",y)) +
  annotate("text", x=1.15, y=0.152,
           label=paste0("r = +", sprintf('%.2f', r),
                        "   (more predictable  →  better offense)"),
           hjust=0, size=3.6, color=ink_secondary, fontface="italic") +
  annotate("text", x=-0.12, y=0.066,
           label="the lone\nunpredictable elite",
           hjust=0.5, size=2.7, color=ink_muted, lineheight=0.9) +
  labs(
    title="The best play-callers are more predictable, not less",
    subtitle="Career conditional predictability vs offensive EPA/play — once you control for the situation, elite callers commit\nHARDER to their tendencies. X = extra pass/run calls a situational guesser gets right per 100 plays, vs the league in the same spots.",
    x="Conditional predictability  (extra plays out of 100 an optimal guesser calls correctly, vs league)",
    y="Offensive EPA / play",
    caption="nflverse play-by-play 2015-2025. Called plays only (qb_dropback or designed rush; kneels/spikes & vegas_wp<5% or >95% garbage time excluded). Pass prob modeled in 384\nsituation cells (down x yds-to-go x field zone x score state x half); caller cell rates empirical-Bayes shrunk toward league (k=15). Play-caller from nflverse\nplaycallers.csv. Career callers with ≥1000 called plays (n=80). Point size = plays. Same-season r=+0.35; controlling for game-script confound flips the naive\n'unpredictable=good' signal (raw entropy r=+0.33) because good offenses simply live in more balanced down-and-distance."
  ) +
  theme_nfl() +
  theme(legend.position=c(0.12,0.90), legend.background=element_rect(fill=col_surface,color=NA))
save_chart(p, "predictability_vs_epa_scatter", width=11, height=7.5)
