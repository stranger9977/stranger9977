# =====================================================================
# THE PRE-SNAP TIP: does the predictability paradox resolve via disguise?
# Hypothesis (coaching lore): elite predictable callers run & pass from
# the SAME looks, so a "known" tendency can't be exploited -> they should
# live in the PREDICTABLE + LOW-TIP corner.
# Metric: within situation cells, how much formation + personnel (the
# pre-snap LOOK) cut run/pass uncertainty BEYOND situation (EB-shrunk).
#   LOW tip = disguised look ; HIGH tip = formation telegraphs the play.
# Restricted to 2016-2023 (nflverse participation formation window).
#
# RESULT: the disguise theory BUSTS. Two honest findings on this chart:
#   (1) The predictable-elite corner the theory needs is EMPTY of stars;
#       elites telegraph the look too (they sit high, not low).
#   (2) The low-tip "disguise" cluster is the SMALL-SAMPLE cluster --
#       EB shrinkage deflates small-n callers' tip, so Pep Hamilton /
#       Chip Kelly / Getsy reading as "elite disguise" is an artifact.
#   The apparent r(tip,EPA)=+0.41 collapses to partial r=0.20 once sample
#   size is controlled and is non-significant once QB cpoe is added -->
#   so we retreat to the DESCRIPTIVE claim only. Point SIZE = sample.
#
# Table built by scripts/pred_tip_disguise_build.R (auditable recipe).
# =====================================================================
suppressMessages(library(data.table))
suppressMessages(library(ggplot2))
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")

tip <- readRDS("/Users/nick/stranger9977/nfl-analysis/scratch/pred_tip_disguise.rds")
tip <- tip[n_look >= 500 & !is.na(epa_play)]

# ---- label sets ------------------------------------------------------
elite_pred <- c("Andy Reid","Sean McVay","Kyle Shanahan","Matt LaFleur","Sean Payton")
exception  <- c("Ben Johnson")                       # low-tip AND good (real, but small n)
disguised_bust <- c("Chip Kelly","Pep Hamilton","Luke Getsy")  # low tip, small n, bad O
lab_set <- c(elite_pred, exception, disguised_bust)

tip[, grp := fifelse(off_play_caller %in% elite_pred, "elite",
              fifelse(off_play_caller %in% exception, "exception",
              fifelse(off_play_caller %in% disguised_bust, "bust", "other")))]
# label carries the NAME + the sample size (n), so the artifact is legible
tip[, lab := fifelse(off_play_caller %in% lab_set,
                     sprintf("%s  (n=%s)", off_play_caller,
                             formatC(n_look, big.mark=",", format="d")),
                     NA_character_)]

# per-label manual placement to avoid collisions (nudge in data units)
nud <- data.table(
  off_play_caller = c("Sean McVay","Sean Payton","Kyle Shanahan","Matt LaFleur","Andy Reid",
                      "Ben Johnson","Luke Getsy","Chip Kelly","Pep Hamilton"),
  nx = c(0.10,   0.10,   -0.55,  0.00,   -0.15,  0.18,   0.18,   0.18,   0.16),
  ny = c(0.0020, 0.0000, 0.0018, 0.0021, 0.0022, 0.0000, -0.0002, 0.0000, 0.0000),
  hj = c(0,      0,      1,      0.5,    1,      0,      0,       0,      0))
tip <- merge(tip, nud, by="off_play_caller", all.x=TRUE)
tip[is.na(nx), c("nx","ny","hj") := .(0, 0, 0.5)]

med_tip <- median(tip$presnap_tip)

# ---- plot ------------------------------------------------------------
col_baseline <- "#c3c2b7"
p <- ggplot(tip, aes(guess_xs, presnap_tip)) +
  # median reference
  geom_hline(yintercept = med_tip, linetype = "22", color = col_baseline, linewidth = .4) +
  geom_vline(xintercept = 0, linetype = "22", color = col_baseline, linewidth = .4) +
  # the corner the DISGUISE theory needs elites to occupy -- and it's empty
  annotate("rect", xmin = 0.8, xmax = 3.4, ymin = 0.004, ymax = med_tip,
           fill = "#1baf7a", alpha = 0.06) +
  annotate("text", x = 2.75, y = 0.0088, color = "#159068", size = 3.2, fontface = "italic",
           hjust = 0.5,
           label = "Disguise theory needs predictable\nelites HERE (hidden look).\nNo star offense is.") +
  # non-labeled callers, sized by sample
  geom_point(data = tip[grp=="other"], aes(fill = epa_play, size = n_look), shape = 21,
             color = "white", stroke = .3, alpha = .9) +
  # highlighted callers on top
  geom_point(data = tip[grp!="other"], aes(fill = epa_play, size = n_look), shape = 21,
             color = ink_primary, stroke = .8) +
  geom_text(aes(x = guess_xs + nx, y = presnap_tip + ny, label = lab, hjust = hj),
            size = 3.05, color = ink_primary, fontface = "bold", lineheight = .9) +
  scale_fill_gradient2(low = pal_div$low, mid = pal_div$mid, high = pal_div$high,
                       midpoint = 0, name = "Career\nEPA/play",
                       breaks = c(-0.15, 0, 0.10),
                       labels = c("-.15", "0", "+.10"),
                       guide = guide_colorbar(order = 1)) +
  scale_size_area(name = "Formation-coded\nplays  (sample)",
                  max_size = 13,
                  breaks = c(1000, 3000, 6000),
                  labels = c("1,000", "3,000", "6,000"),
                  guide = guide_legend(order = 2, override.aes = list(fill = col_baseline,
                                                                      color = ink_secondary))) +
  scale_x_continuous(breaks = seq(0,3,1),
                     labels = c("league", "+1", "+2", "+3"),
                     expand = expansion(mult = c(0.14, 0.20))) +
  scale_y_continuous(labels = function(x) sprintf("%.3f", x),
                     expand = expansion(mult = c(.06, .12))) +
  labs(
    title = "Elite callers don't hide the tell either — the 'disguised-look' corner is empty of stars",
    subtitle = "Pre-snap tip = run/pass certainty that formation + personnel add BEYOND down/distance/score. Higher = the look gives it away.\nPoint size = sample: the low-tip “disguise” cluster is the SMALL-sample cluster, where shrinkage deflates the tip.",
    x = "Situational predictability  (extra run/pass calls a guesser nails per 100, vs league)  → more predictable",
    y = "Pre-snap tip (bits)   → more telegraphed",
    caption = paste0(
      "Called pass/run plays, 2016-2023 (nflverse participation formation window; 0.54% of called plays lack a charted formation, dropped). 76 callers with ≥500 formation-coded plays; point area ∝ sample. Built by scripts/pred_tip_disguise_build.R.\n",
      "Look = offense_formation × personnel bucket (11/12/21/13/empty/other). Within-(cell) and within-(cell×look) run/pass entropy, empirical-Bayes shrunk (K=15). Shrinkage DEFLATES small-n callers' tip, so Pep Hamilton (764) / Chip Kelly (739) / Getsy (1,676)\n",
      "reading as “elite disguise” is largely a sample artifact, not real disguise. Apparent r(tip,EPA)=+0.41 falls to partial r=0.20 controlling log(sample), and tip is non-significant once QB accuracy (cpoe) is added (p=0.32). Honest claim is DESCRIPTIVE:\n",
      "disguise does not rescue the paradox — elite offenses are plainly not in the low-tip zone. (One real low-tip elite exists: Ben Johnson, but on a small n=1,910.) Career EPA & predictability from the full 2015-2025 table.")
  ) +
  theme_nfl() +
  theme(legend.position = c(0.995, 0.30),
        legend.justification = c(1, 0.5),
        legend.background = element_rect(fill = col_surface, color = NA),
        legend.key.height = unit(13, "pt"),
        legend.spacing.y = unit(2, "pt"),
        axis.title.x = element_text(size = 10.5),
        axis.title.y = element_text(size = 10.5),
        plot.caption = element_text(size = 6.9, lineheight = 1.12))

save_chart(p, "presnap-tip-disguise", width = 11.2, height = 7.4)
cat("median tip =", round(med_tip,4), "\n")
