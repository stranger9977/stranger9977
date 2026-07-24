# The Rational Foul: is a deep DPI cheaper for the defense than the catch?
#
# Compares mean EPA (offense's perspective) of three outcomes on downfield
# throws, matched on depth: a completion at that air-yards depth, an enforced
# spot-foul DPI at that penalty-yards depth, and an incompletion at that depth.
# Hypothesis: DPI < completion because the spot foul deletes YAC and the TD
# tail, and the gap widens with depth.
#
# Data: nflverse play-by-play 2015-2024 (pbp_slim.rds).
# Guards: enforced penalties only (penalty_yards > 0 drops offsetting /
# declined), end-of-half heaves excluded (half_seconds_remaining > 10),
# completions/incompletions with any penalty on the play excluded,
# interceptions excluded from the incompletion group.
# Note: DPI rows are play_type == 'no_play' but carry populated EPA.

library(data.table)
library(ggplot2)
library(scales)
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")

set.seed(42)
pbp  <- setDT(readRDS("/home/user/stranger9977/nfl-analysis/data/pbp_slim.rds"))
base <- pbp[!is.na(epa) & half_seconds_remaining > 10]

dpi <- base[penalty == 1 & penalty_type == "Defensive Pass Interference" &
            penalty_yards > 0][, depth := penalty_yards]
comp <- base[complete_pass == 1 & penalty == 0 &
             !is.na(air_yards)][, depth := air_yards]
inc  <- base[incomplete_pass == 1 & penalty == 0 & interception == 0 &
             !is.na(air_yards)][, depth := air_yards]

bin_breaks <- c(10, 15, 20, 25, 30, 35, Inf)
bin_labels <- c("10-14", "15-19", "20-24", "25-29", "30-34", "35+")
bin_mid    <- c(12, 17, 22, 27, 32, 41)  # 41 = mean depth in 35+ bin (both groups)
bin_of <- function(d) cut(d, bin_breaks, right = FALSE, labels = bin_labels)

groups <- rbindlist(list(
  dpi[,  .(group = "Spot-foul DPI", bin = bin_of(depth), epa, season)],
  comp[, .(group = "Completion",    bin = bin_of(depth), epa, season)],
  inc[,  .(group = "Incompletion",  bin = bin_of(depth), epa, season)]
))[!is.na(bin)]

boot_ci <- function(x, B = 4000) {
  n  <- length(x)
  bs <- replicate(B, mean(x[sample.int(n, n, TRUE)]))
  list(mean_epa = mean(x),
       lo = unname(quantile(bs, .025)),
       hi = unname(quantile(bs, .975)),
       n  = n)
}
res <- groups[, boot_ci(epa), by = .(group, bin)]
res[, x := bin_mid[as.integer(bin)]]
print(res[order(bin, group)])

wide <- dcast(res, bin + x ~ group, value.var = "mean_epa")
setnames(wide, c("Spot-foul DPI"), c("DPI"))
wide[, gap := Completion - DPI]
print(wide)

# Era-stability check (printed, not charted)
print(dcast(groups[, .(m = mean(epa)),
                   by = .(group, bin, era = fifelse(season < 2020, "2015-19", "2020-24"))],
            bin + era ~ group, value.var = "m"))

# What the foul deletes: TD rate + YAC on completions per bin
dec <- base[complete_pass == 1 & penalty == 0 & !is.na(air_yards)
            ][, bin := bin_of(air_yards)][!is.na(bin),
              .(td_rate = mean(pass_touchdown), mean_yac = mean(yards_after_catch, na.rm = TRUE)),
              by = bin][order(bin)]
print(dec)

# ---- chart ----------------------------------------------------------------
res[, group := factor(group, levels = c("Completion", "Spot-foul DPI", "Incompletion"))]
gap_35 <- wide[bin == "35+", gap]
n_lab  <- res[group == "Spot-foul DPI"][order(bin)]

p <- ggplot(res, aes(x, mean_epa, color = group)) +
  geom_ribbon(data = wide, aes(x = x, ymin = DPI, ymax = Completion),
              inherit.aes = FALSE, fill = pal_cat[1], alpha = 0.10) +
  geom_hline(yintercept = 0, color = col_baseline, linewidth = 0.4) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0, linewidth = 0.6, alpha = 0.55) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.2) +
  # gap bracket at the deepest bin
  annotate("segment", x = 42.6, xend = 42.6,
           y = wide[bin == "35+", DPI], yend = wide[bin == "35+", Completion],
           color = ink_secondary, linewidth = 0.5) +
  annotate("text", x = 43.2, y = wide[bin == "35+", (DPI + Completion) / 2],
           label = paste0("the foul saves\n", number(gap_35, accuracy = .01), " EPA"),
           hjust = 0, size = 3.4, color = ink_primary, fontface = "bold", lineheight = .95) +
  annotate("text", x = 8.5, y = 2.45,
           label = "shallow: foul and catch\ncost the same", hjust = 0, size = 3.1,
           color = ink_secondary, lineheight = .95) +
  annotate("segment", x = 11.4, xend = 12, y = 2.2, yend = 1.62,
           color = ink_muted, linewidth = 0.35) +
  annotate("text", x = 30, y = 2.05,
           label = "value of the foul:\nYAC + touchdowns erased\n(35+ yd catches: 34% TDs, 7.1 avg YAC)",
           hjust = 0.5, size = 3.1, color = ink_secondary, lineheight = 1.0) +
  # per-bin DPI sample sizes along the bottom
  annotate("text", x = n_lab$x, y = -1.55,
           label = paste0("n=", comma(n_lab$n)), size = 2.9, color = ink_muted) +
  annotate("text", x = 9.4, y = -1.55, label = "DPI plays:", hjust = 1,
           size = 2.9, color = ink_muted) +
  scale_color_manual(values = pal_cat[1:3], name = NULL) +
  scale_x_continuous(breaks = bin_mid, labels = bin_labels,
                     limits = c(7.5, 47), expand = expansion(0)) +
  scale_y_continuous(breaks = seq(-1, 4, 1)) +
  coord_cartesian(clip = "off") +
  labs(
    title    = "The rational foul: on 35+ yard throws, grabbing the receiver costs\nthe defense 0.8 EPA less than letting him catch it",
    subtitle = "Mean expected points added (offense's view) by outcome and depth: a spot-foul DPI moves the ball\nthe same distance as the catch, but deletes yards-after-catch and the touchdown. 95% bootstrap CIs.",
    x = "Depth of target / penalty spot (yards downfield)",
    y = "Mean EPA for the offense",
    caption = "Data: nflverse play-by-play, 2015-2024 regular + postseason. Enforced DPI only (offsetting/declined excluded); final 10 seconds of each half\nexcluded; interceptions and penalty-flagged catches excluded from pass groups. Minimum 149 DPI plays per depth bin. Effect stable 2015-19 vs 2020-24."
  ) +
  theme_nfl() +
  theme(legend.position = c(0.13, 0.36),
        legend.background = element_rect(fill = col_surface, color = NA))

save_chart(p, "rational-foul-dpi")
