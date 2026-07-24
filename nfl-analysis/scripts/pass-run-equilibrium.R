# =============================================================================
# Optimal play sequencing across game-state slices, 2015-2025
#
# Chart 1 (pass-run-equilibrium): where the league is furthest from run/pass
#   indifference. Called pass (qb_dropback=1, scrambles included) minus called
#   run (rush=1, no scramble) in EPA/play and success rate, by slice x down,
#   95% CIs, n and league pass rate per cell. Garbage time removed via
#   vegas_wp 5-95%; kneels/spikes/no-plays excluded.
#
# Chart 2 (run-sets-up-nothing): first-order sequence memory. Within the SAME
#   drive and at FIXED exact down-and-distance (open field, yardline 21-85),
#   does the previous call change (a) the next-play mix, (b) next-play EPA?
# =============================================================================
suppressMessages({library(data.table); library(ggplot2); library(scales)})
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")

d <- readRDS("/home/user/stranger9977/nfl-analysis/data/pbp_slim.rds")
setDT(d)
d <- d[, .(play_id, game_id, season, posteam, qtr, down, ydstogo, yardline_100,
           goal_to_go, half_seconds_remaining, game_seconds_remaining, play_type,
           qb_dropback, qb_scramble, qb_kneel, qb_spike, rush, epa, vegas_wp,
           success, score_differential, drive)]
invisible(gc())

# Called run/pass plays only
d <- d[play_type %in% c("pass", "run") & qb_kneel == 0 & qb_spike == 0 &
       !is.na(epa) & !is.na(down)]
d[, called_pass := as.integer(qb_dropback == 1)]          # scrambles = pass calls
d <- d[qb_dropback == 1 | (rush == 1 & qb_scramble == 0)] # drop aborted oddballs
dwp <- d[vegas_wp >= 0.05 & vegas_wp <= 0.95]             # drop garbage time

# ---------------------------------------------------------------- Chart 1 ----
mk <- function(dt, slice, dl) dt[, .(slice, downlab = dl, called_pass, epa, success)]
cells <- rbindlist(list(
  mk(dwp[down == 1 & ydstogo == 10 & yardline_100 %between% c(40, 80)], "Open field\n(own 20 to opp 40)", "1st & 10"),
  mk(dwp[down == 2 & ydstogo %between% c(3, 6) & yardline_100 %between% c(40, 80)], "Open field\n(own 20 to opp 40)", "2nd & 3-6"),
  mk(dwp[down == 2 & ydstogo >= 7 & yardline_100 %between% c(40, 80)], "Open field\n(own 20 to opp 40)", "2nd & 7+"),
  mk(dwp[yardline_100 %between% c(6, 20) & down == 1], "Red zone\n(6-20 yd line)", "1st down"),
  mk(dwp[yardline_100 %between% c(6, 20) & down == 2], "Red zone\n(6-20 yd line)", "2nd down"),
  mk(dwp[goal_to_go == 1 & yardline_100 <= 5 & down == 1], "Goal-to-go,\ninside the 5", "1st down"),
  mk(dwp[goal_to_go == 1 & yardline_100 <= 5 & down == 2], "Goal-to-go,\ninside the 5", "2nd down"),
  mk(dwp[goal_to_go == 1 & yardline_100 <= 5 & down %in% 3:4], "Goal-to-go,\ninside the 5", "3rd/4th down"),
  mk(dwp[down == 3 & ydstogo <= 2 & yardline_100 > 5], "Short yardage\n(to go: 1-2)", "3rd down"),
  mk(dwp[down == 4 & ydstogo <= 2 & yardline_100 > 5], "Short yardage\n(to go: 1-2)", "4th down"),
  mk(dwp[game_seconds_remaining <= 300 & qtr >= 4 & abs(score_differential) <= 8 & down %in% 1:2],
     "One-score game,\nfinal 5:00", "1st/2nd down"),
  mk(dwp[half_seconds_remaining <= 120 & down %in% 1:2], "Two-minute drill", "1st/2nd down")
))

eq <- cells[, .(
  n = .N, n_pass = sum(called_pass), n_run = sum(called_pass == 0),
  pass_rate = mean(called_pass),
  gap = mean(epa[called_pass == 1]) - mean(epa[called_pass == 0]),
  se  = sqrt(var(epa[called_pass == 1]) / sum(called_pass) +
             var(epa[called_pass == 0]) / sum(called_pass == 0)),
  sr_gap = mean(success[called_pass == 1]) - mean(success[called_pass == 0]),
  sr_se  = sqrt(var(success[called_pass == 1]) / sum(called_pass) +
                var(success[called_pass == 0]) / sum(called_pass == 0))
), by = .(slice, downlab)]
stopifnot(all(eq$n_pass >= 900 & eq$n_run >= 400))   # enforce minimum samples

eq[, cell := paste0(downlab, "  ")]
eq[, cell_lab := paste0(downlab, "   (pass ", round(100 * pass_rate), "%, n=",
                        formatC(n, format = "d", big.mark = ","), ")")]
slice_order <- c("Open field\n(own 20 to opp 40)", "Red zone\n(6-20 yd line)",
                 "One-score game,\nfinal 5:00", "Two-minute drill",
                 "Short yardage\n(to go: 1-2)", "Goal-to-go,\ninside the 5")
eq[, slice := factor(slice, levels = rev(slice_order))]
setorder(eq, slice, gap)
eq[, cell_lab := factor(cell_lab, levels = cell_lab)]

long <- rbind(
  eq[, .(slice, cell_lab, metric = "EPA per play gap", val = gap, lo = gap - 1.96 * se, hi = gap + 1.96 * se)],
  eq[, .(slice, cell_lab, metric = "Success rate gap", val = sr_gap, lo = sr_gap - 1.96 * sr_se, hi = sr_gap + 1.96 * sr_se)]
)
long[, metric := factor(metric, levels = c("EPA per play gap", "Success rate gap"))]
long[, favors := ifelse(val >= 0, "Pass favored", "Run favored")]

p1 <- ggplot(long, aes(x = val, y = cell_lab, color = favors)) +
  geom_vline(xintercept = 0, color = col_baseline, linewidth = 0.5) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.22, linewidth = 0.5) +
  geom_point(size = 2.6) +
  geom_text(aes(label = ifelse(metric == "EPA per play gap", sprintf("%+.2f", val),
                               sprintf("%+.0f", 100 * val)),
                x = ifelse(val >= 0, hi, lo), hjust = ifelse(val >= 0, -0.35, 1.35)),
            size = 3, fontface = "bold", show.legend = FALSE) +
  facet_grid(slice ~ metric, scales = "free", space = "free_y", switch = "y") +
  scale_color_manual(values = c("Pass favored" = pal_cat[1], "Run favored" = pal_cat[8]), name = NULL) +
  scale_x_continuous(expand = expansion(mult = 0.28)) +
  labs(
    title = "Pass more everywhere in the open field — but inside the 5, the edge flips to the run",
    subtitle = paste0("Called pass minus called run (positive = passing wins), with 95% CI. Right panel in success-rate points.\n",
                      "Goal-to-go 3rd/4th down: runs score/succeed 13 pts more often, yet the league passes 67% of the time. ",
                      "On 1st & 10 in the open field, passing is +0.20 EPA and the mix is still 53/47."),
    x = "Pass minus run (EPA per play  |  success-rate points)", y = NULL,
    caption = paste0("nflfastR 2015-2025 | called pass = dropbacks incl. scrambles & sacks; called run = designed runs | kneels, spikes, no-plays excluded | ",
                     "garbage time removed (pregame-market win prob 5-95%) | labels: league pass rate & plays per cell | min 400 per play type per cell.")
  ) +
  theme_nfl() +
  theme(strip.text.y.left = element_text(angle = 0, color = ink_secondary, face = "bold", size = 9, hjust = 1),
        strip.text.x = element_text(face = "bold", color = ink_secondary),
        strip.placement = "outside",
        panel.spacing.y = unit(0.6, "lines"),
        legend.position = "top", legend.justification = "left",
        axis.text.y = element_text(color = ink_primary, size = 9))
save_chart(p1, "pass-run-equilibrium", width = 11, height = 7.5)

# ---------------------------------------------------------------- Chart 2 ----
# Sequence memory: previous offensive snap in the SAME drive
setorder(d, game_id, drive, play_id)
d[, prev_pass := shift(called_pass), by = .(game_id, drive, posteam)]
s <- d[!is.na(prev_pass) & vegas_wp >= 0.05 & vegas_wp <= 0.95 &
       yardline_100 %between% c(21, 85)]
s[, state := fcase(
  down == 1 & ydstogo == 10,             "1st & 10 (mid-drive)",
  down == 2 & ydstogo == 10,             "2nd & 10",
  down == 2 & ydstogo %between% c(8, 9), "2nd & 8-9",
  down == 2 & ydstogo %between% c(6, 7), "2nd & 6-7",
  down == 2 & ydstogo %between% c(4, 5), "2nd & 4-5",
  down == 2 & ydstogo %between% c(1, 3), "2nd & 1-3",
  down == 3 & ydstogo %between% c(1, 2), "3rd & 1-2",
  down == 3 & ydstogo %between% c(3, 6), "3rd & 3-6",
  default = NA_character_)]
s <- s[!is.na(state)]

sq <- s[, .(
  n = .N,
  pr_run  = mean(called_pass[prev_pass == 0]),   # pass rate after a run
  pr_pass = mean(called_pass[prev_pass == 1]),   # pass rate after a pass
  np_r = sum(called_pass == 1 & prev_pass == 0), np_p = sum(called_pass == 1 & prev_pass == 1),
  dp   = mean(epa[called_pass == 1 & prev_pass == 0]) - mean(epa[called_pass == 1 & prev_pass == 1]),
  sedp = sqrt(var(epa[called_pass == 1 & prev_pass == 0]) / sum(called_pass == 1 & prev_pass == 0) +
              var(epa[called_pass == 1 & prev_pass == 1]) / sum(called_pass == 1 & prev_pass == 1)),
  nr_r = sum(called_pass == 0 & prev_pass == 0), nr_p = sum(called_pass == 0 & prev_pass == 1),
  dr   = mean(epa[called_pass == 0 & prev_pass == 1]) - mean(epa[called_pass == 0 & prev_pass == 0]),
  sedr = sqrt(var(epa[called_pass == 0 & prev_pass == 1]) / sum(called_pass == 0 & prev_pass == 1) +
              var(epa[called_pass == 0 & prev_pass == 0]) / sum(called_pass == 0 & prev_pass == 0))
), by = state]
stopifnot(all(sq$np_r >= 500 & sq$np_p >= 500))

st_order <- c("1st & 10 (mid-drive)", "2nd & 1-3", "2nd & 4-5", "2nd & 6-7",
              "2nd & 8-9", "2nd & 10", "3rd & 1-2", "3rd & 3-6")
sq[, state := factor(state, levels = rev(st_order))]

mixdt <- melt(sq[, .(state, `after a run` = pr_run, `after a pass` = pr_pass)],
              id.vars = "state", variable.name = "prev", value.name = "pr")

pay <- rbind(
  sq[, .(state, series = "Pass EPA: after run vs after pass", val = dp, lo = dp - 1.96 * sedp, hi = dp + 1.96 * sedp, ok = TRUE)],
  sq[, .(state, series = "Run EPA: after pass vs after run",  val = dr, lo = dr - 1.96 * sedr, hi = dr + 1.96 * sedr, ok = nr_r >= 500 & nr_p >= 500)]
)[ok == TRUE][, ok := NULL]

pA <- ggplot(mixdt, aes(x = pr, y = state, color = prev)) +
  geom_line(aes(group = state), color = col_baseline, linewidth = 1.4) +
  geom_point(size = 3) +
  geom_text(data = sq, aes(x = pmax(pr_run, pr_pass), y = state,
                           label = sprintf("%+.0f pts", 100 * (pr_run - pr_pass))),
            inherit.aes = FALSE, hjust = -0.25, size = 3, color = ink_secondary, fontface = "bold") +
  scale_x_continuous(labels = percent_format(accuracy = 1), limits = c(0.25, 1.12),
                     breaks = seq(0.3, 0.9, 0.2)) +
  scale_color_manual(values = c(`after a run` = pal_cat[2], `after a pass` = pal_cat[1]), name = "Pass rate:") +
  labs(subtitle = "Callers alternate: next-play pass rate,\nsame exact down & distance", x = "Next-play pass rate", y = NULL) +
  theme_nfl() + theme(legend.position = "top", legend.justification = "left",
                      axis.text.y = element_text(color = ink_primary, size = 10),
                      plot.subtitle = element_text(face = "bold"))

pB <- ggplot(pay, aes(x = val, y = state, color = series)) +
  geom_vline(xintercept = 0, color = col_baseline, linewidth = 0.5) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.25, linewidth = 0.5,
                 position = position_dodge(width = 0.55)) +
  geom_point(size = 2.6, position = position_dodge(width = 0.55)) +
  scale_color_manual(values = setNames(pal_cat[c(3, 7)],
                                       c("Pass EPA: after run vs after pass", "Run EPA: after pass vs after run")),
                     name = NULL, guide = guide_legend(nrow = 2)) +
  scale_x_continuous(limits = c(-0.30, 0.30)) +
  labs(subtitle = "...but the payoff doesn't move: alternation\nbonus in EPA/play, 95% CI", x = "EPA per play vs same call repeated", y = NULL) +
  theme_nfl() + theme(legend.position = "top", legend.justification = "left",
                      axis.text.y = element_blank(),
                      plot.subtitle = element_text(face = "bold"))

library(grid)
p2 <- ggplot() + theme_void()  # placeholder if patchwork missing; use gtable side-by-side
# simple side-by-side via gridExtra-free approach: use patchwork if available, else cowplot, else grid
title_txt <- "The run does not set up the pass: the defense has no memory of your last call"
sub_txt <- paste0("Same drive, same exact down & distance (open field, yardline 21-85), 2015-2025. On 2nd & 10, callers pass 80% after a stuffed run\n",
                  "vs 63% after an incompletion — an 18-point swing — yet the next pass gains the SAME EPA either way (-0.00). No cell shows a\n",
                  "reliable positive alternation bonus; on 2nd & 8-9 passing after a run is actually 0.08 EPA WORSE.")
cap_txt <- "nflfastR 2015-2025 | previous offensive snap in the same drive | called pass incl. scrambles/sacks | garbage time removed (win prob 5-95%) | min 500 plays per side per cell; run-EPA series hidden where under sample."

png_path <- file.path("/home/user/stranger9977/nfl-analysis/charts", "run-sets-up-nothing.png")
png(png_path, width = 11 * 150, height = 7 * 150, res = 150, bg = col_surface)
grid.newpage()
pushViewport(viewport(layout = grid.layout(4, 2,
  heights = unit(c(0.055, 0.115, 1, 0.055), "npc"), widths = unit(c(0.52, 0.48), "npc"))))
grid.text(title_txt, x = unit(0.015, "npc"), just = "left",
          vp = viewport(layout.pos.row = 1, layout.pos.col = 1:2),
          gp = gpar(fontface = "bold", cex = 1.25, col = ink_primary))
grid.text(sub_txt, x = unit(0.015, "npc"), just = "left",
          vp = viewport(layout.pos.row = 2, layout.pos.col = 1:2),
          gp = gpar(cex = 0.85, col = ink_secondary))
print(pA, vp = viewport(layout.pos.row = 3, layout.pos.col = 1))
print(pB, vp = viewport(layout.pos.row = 3, layout.pos.col = 2))
grid.text(cap_txt, x = unit(0.015, "npc"), just = "left",
          vp = viewport(layout.pos.row = 4, layout.pos.col = 1:2),
          gp = gpar(cex = 0.6, col = ink_muted))
dev.off()
cat("SAVED:", png_path, "\n")

# ------------------------------------------------------------- verification --
cat("\n== Chart 1 table ==\n")
print(eq[, .(slice, downlab, n, pass_rate = round(pass_rate, 3), gap = round(gap, 3),
             lo = round(gap - 1.96 * se, 3), hi = round(gap + 1.96 * se, 3),
             sr_gap = round(sr_gap, 3))], nrow = 30)
cat("\n== Chart 2 table ==\n")
print(sq[order(-as.integer(state)),
         .(state, pr_run = round(pr_run, 3), pr_pass = round(pr_pass, 3),
           dp = round(dp, 3), sedp = round(sedp, 3), dr = round(dr, 3), sedr = round(sedr, 3),
           np_r, np_p, nr_r, nr_p)], nrow = 30)
