# Follow-up to rational-foul-dpi: the foul-vs-contest GAMBLE.
# The foul trades a lottery (contest: p*EPA_comp + (1-p)*EPA_inc) for a
# near-certain outcome (EPA_dpi). Break-even belief:
#   p* = (EPA_dpi - EPA_inc) / (EPA_comp - EPA_inc)
# Compare p* per depth bin against what receivers actually catch at that
# depth: all targets, and contested targets (FTN is_contested_ball 2022-24).
library(data.table)
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")

pbp  <- setDT(readRDS("/home/user/stranger9977/nfl-analysis/data/pbp_slim.rds"))
base <- pbp[!is.na(epa) & half_seconds_remaining > 10 & season <= 2024]

bin_breaks <- c(10, 15, 20, 25, 30, 35, Inf)
bin_labels <- c("10-14", "15-19", "20-24", "25-29", "30-34", "35+")
bin_of <- function(d) cut(d, bin_breaks, right = FALSE, labels = bin_labels)

dpi  <- base[penalty == 1 & penalty_type == "Defensive Pass Interference" &
             penalty_yards > 0][, bin := bin_of(penalty_yards)]
comp <- base[complete_pass == 1 & penalty == 0 & !is.na(air_yards)
             ][, bin := bin_of(air_yards)]
inc  <- base[incomplete_pass == 1 & penalty == 0 & interception == 0 &
             !is.na(air_yards)][, bin := bin_of(air_yards)]

epa_tab <- rbindlist(list(
  dpi[!is.na(bin),  .(g = "dpi",  epa, bin)],
  comp[!is.na(bin), .(g = "comp", epa, bin)],
  inc[!is.na(bin),  .(g = "inc",  epa, bin)]
))[, .(m = mean(epa)), by = .(g, bin)]
w <- dcast(epa_tab, bin ~ g, value.var = "m")
w[, p_star := (dpi - inc) / (comp - inc)]

# Actual catch rates by depth: all targets (excl. penalties, INT counts as fail)
tgt <- base[(complete_pass == 1 | incomplete_pass == 1 | interception == 1) &
            penalty == 0 & !is.na(air_yards)][, bin := bin_of(air_yards)]
catch <- tgt[!is.na(bin), .(catch_rate = mean(complete_pass), n = .N,
                            mean_cp = mean(cp, na.rm = TRUE)), by = bin]

# Contested-ball catch rate, FTN 2022-24
ftn <- rbindlist(lapply(2022:2024, function(y)
  fread(sprintf("/home/user/stranger9977/nfl-analysis/data/ftn_charting_%d.csv.gz", y),
        select = c("nflverse_game_id", "nflverse_play_id", "is_contested_ball"))))
setnames(ftn, c("game_id", "play_id", "contested"))
tgt22 <- merge(tgt[season >= 2022], ftn, by = c("game_id", "play_id"))
contested <- tgt22[contested == TRUE & !is.na(bin),
                   .(contested_catch_rate = mean(complete_pass), n_contested = .N), by = bin]

out <- Reduce(function(a, b) merge(a, b, by = "bin"), list(w, catch, contested))
setorder(out, bin)
print(out[, .(bin, epa_comp = round(comp, 2), epa_dpi = round(dpi, 2),
              epa_inc = round(inc, 2), p_star = round(p_star, 2),
              catch_rate = round(catch_rate, 2), mean_cp = round(mean_cp, 2),
              n_targets = n, contested_catch_rate = round(contested_catch_rate, 2),
              n_contested)])

# ---- chart: break-even belief vs reality ----------------------------------
bin_mid <- c(12, 17, 22, 27, 32, 41)
out[, x := bin_mid[as.integer(bin)]]
long <- rbindlist(list(
  out[, .(x, bin, val = pmin(p_star, 1), series = "Break-even catch probability the foul needs")],
  out[, .(x, bin, val = contested_catch_rate, series = "Actual catch rate, contested balls (FTN 2022-24)")],
  out[, .(x, bin, val = catch_rate, series = "Actual catch rate, all targets")]
))
long[, series := factor(series, levels = unique(series))]

p <- ggplot(long, aes(x, val, color = series)) +
  geom_ribbon(data = dcast(long, x ~ series, value.var = "val"),
              aes(x = x,
                  ymin = `Actual catch rate, contested balls (FTN 2022-24)`,
                  ymax = `Break-even catch probability the foul needs`),
              inherit.aes = FALSE, fill = pal_cat[2], alpha = 0.08) +
  geom_line(linewidth = 1.1) + geom_point(size = 2.2) +
  annotate("text", x = 41, y = 0.905,
           label = "p* = 83%: the belief the foul\nneeds to beat contesting", hjust = 1,
           size = 3.2, color = ink_secondary, lineheight = .95) +
  annotate("text", x = 41, y = 0.56,
           label = "the gamble gap:\nfoul only when you're sure\n(i.e., when you're beaten)",
           hjust = 1, size = 3.3, fontface = "bold", color = ink_primary, lineheight = 1) +
  annotate("text", x = 41, y = 0.24, label = "29-31% actually caught",
           hjust = 1, size = 3.2, color = ink_secondary) +
  annotate("text", x = 12.6, y = 1.045,
           label = "shallow: foul never pays (break-even > 100%)", hjust = 0,
           size = 3.1, color = ink_secondary) +
  scale_color_manual(values = c(pal_cat[2], pal_cat[1], pal_cat[3]), name = NULL,
                     guide = guide_legend(nrow = 3)) +
  scale_x_continuous(breaks = bin_mid, labels = out$bin) +
  scale_y_continuous(labels = scales::percent, breaks = seq(0, 1, .25),
                     limits = c(0, 1.07)) +
  labs(
    title    = "The foul is insurance, not a bargain: it needs an 83% catch\nto pay, and deep balls are caught 29% of the time",
    subtitle = "Break-even catch probability where a spot-foul DPI equals contesting the throw (foul EPA vs the\ncompletion/incompletion lottery), against what receivers actually catch at each depth.",
    x = "Depth of target / penalty spot (yards downfield)",
    y = "Catch probability",
    caption = "Data: nflverse play-by-play 2015-2024 (EPA by outcome, catch rates; n = 3,077-23,642 targets per bin); FTN contested-ball charting 2022-24\n(n = 238-1,349 per bin). Break-even p* = (EPA_DPI - EPA_inc) / (EPA_comp - EPA_inc). Rational rule: contest the ball unless beaten badly enough\nthat the catch is near-certain - then, and only then, the 0.8 EPA discount from the companion chart applies."
  ) +
  theme_nfl() +
  theme(legend.position = c(0.235, 0.14),
        legend.background = element_rect(fill = col_surface, color = NA))
save_chart(p, "rational-foul-breakeven")
