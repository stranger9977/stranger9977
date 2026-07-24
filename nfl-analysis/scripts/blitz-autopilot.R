# The Blitz Buys Pressure at Retail Price — per-QB break-even map
# ---------------------------------------------------------------
# Hypothesis test + twist: pressure EPA is identical whether the defense blitzed
# or rushed four; a failed blitz is materially worse than a failed 4-man rush.
# So a blitz only pays if the pressure-rate bump it buys clears a QB-specific
# break-even. We solve that break-even per QB (2022-23 FTN charting) and ask
# whether defensive coordinators' actual blitz rates track it. They don't.
#
# Verified league 2x2 (EPA/play allowed, 2022-23, screens/spikes excluded):
#   4-man no pressure +0.22 | 4-man pressure -0.29   (pressure rate 27.5%)
#   blitz no pressure +0.30 | blitz pressure -0.31   (pressure rate 39.8%)
# Structure survives situation adjustment (xpass-decile x season residuals:
# -0.38 vs -0.39 with pressure; +0.15 vs +0.23 without) and holds in each season.

library(data.table)
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")

d <- "/home/user/stranger9977/nfl-analysis/data/"

ftn <- rbindlist(lapply(2022:2023, function(y)
  fread(paste0(d, "ftn_charting_", y, ".csv.gz"),
        select = c("nflverse_game_id", "nflverse_play_id", "n_blitzers", "is_screen_pass"))))
part <- rbindlist(lapply(2022:2023, function(y)
  fread(paste0(d, "pbp_participation_", y, ".csv.gz"),
        select = c("nflverse_game_id", "play_id", "was_pressure"))))
pbp <- readRDS(paste0(d, "pbp_slim.rds"))
pbp <- pbp[season %in% 2022:2023 & qb_dropback == 1 & qb_spike == 0,
           .(game_id, play_id, season, epa, passer_player_name, vegas_wp)]

setnames(ftn, c("nflverse_game_id", "nflverse_play_id"), c("game_id", "play_id"))
setnames(part, "nflverse_game_id", "game_id")
dt <- merge(merge(pbp, ftn, by = c("game_id", "play_id")), part, by = c("game_id", "play_id"))
dt <- dt[is_screen_pass == FALSE & !is.na(was_pressure) & !is.na(epa) & passer_player_name != ""]
dt[, blitz    := n_blitzers > 0]
dt[, pressure := was_pressure == 1]

# ---- per-QB cells (min 400 dropbacks over the two seasons) -------------------
qb <- dt[, .(
  n          = .N,
  blitz_rate = mean(blitz),
  p4  = mean(pressure[!blitz]),            # pressure rate, 4-man rush
  pb  = mean(pressure[blitz]),             # pressure rate, blitz
  F_N = mean(epa[!blitz & !pressure]), n_FN = sum(!blitz & !pressure),
  B_N = mean(epa[blitz  & !pressure]), n_BN = sum(blitz  & !pressure),
  P_epa = mean(epa[pressure]),         n_P  = sum(pressure),
  v_play = var(epa)
), by = passer_player_name][n >= 400]

# Empirical-Bayes shrinkage of noisy per-QB cell means toward the league mean.
# k = (within-play EPA variance) / (estimated across-QB variance of true cell means)
shrink <- function(m, n, v_play) {
  pv <- max(var(m) - mean(v_play / n), 0.002)
  k  <- mean(v_play) / pv
  (n * m + k * weighted.mean(m, n)) / (n + k)
}
qb[, F_Ns := shrink(F_N,   n_FN, v_play)]
qb[, B_Ns := shrink(B_N,   n_BN, v_play)]
qb[, P_s  := shrink(P_epa, n_P,  v_play)]   # pooled: "pressure is pressure"

# Break-even: pressure rate pb* at which blitz EPA equals 4-man-rush EPA
#   pb* (P - B_N) = p4 P + (1 - p4) F_N - B_N
qb[, pb_star     := (p4 * P_s + (1 - p4) * F_Ns - B_Ns) / (P_s - B_Ns)]
qb[, bump_needed := pb_star - p4]
qb[, bump_obs    := pb - p4]
qb[, surplus     := 100 * (bump_obs - bump_needed)]   # percentage points
qb[, clears      := surplus > 0]

fit <- lm(blitz_rate ~ surplus, qb)
r   <- cor(qb$blitz_rate, qb$surplus)
pv  <- summary(fit)$coefficients["surplus", 4]
cat(sprintf("QBs: %d | clear break-even: %.0f%% | cor(blitz rate, surplus) = %.2f (p = %.2f)\n",
            nrow(qb), 100 * mean(qb$clears), r, pv))

# ---- chart -------------------------------------------------------------------
xcap <- 30
qb[, x := pmin(surplus, xcap)]  # squish the one extreme point (J.Allen, +58pp)
lab_qbs <- c("J.Allen", "G.Smith", "D.Jones", "T.Brady", "P.Mahomes",
             "J.Burrow", "T.Tagovailoa", "K.Murray", "B.Purdy", "D.Prescott",
             "J.Herbert", "R.Wilson", "J.Hurts")
qb[, lab := fifelse(passer_player_name %in% lab_qbs, passer_player_name, "")]
qb[passer_player_name == "J.Allen", lab := "J.Allen (+58pp)"]

col_pays <- pal_div$low; col_burn <- pal_div$high

library(ggrepel)

p <- ggplot(qb, aes(x = x, y = blitz_rate)) +
  geom_vline(xintercept = 0, color = col_baseline, linewidth = 0.6) +
  geom_smooth(method = "lm", se = FALSE, color = ink_muted,
              linetype = "dashed", linewidth = 0.5) +
  geom_point(aes(color = clears), size = 2.6, alpha = 0.9) +
  geom_text_repel(aes(label = lab), color = ink_secondary, size = 2.9,
                  max.overlaps = Inf, box.padding = 0.25, point.padding = 0.15,
                  segment.color = col_baseline, segment.size = 0.25,
                  min.segment.length = 0.3, seed = 7) +
  annotate("text", x = -14.5, y = 0.355, label = "Blitz never pays at the\npressure bump achieved",
           color = col_burn, size = 3.1, fontface = "bold", hjust = 0, lineheight = 0.95) +
  annotate("text", x = 2, y = 0.355, label = "Blitzing clears break-even",
           color = col_pays, size = 3.1, fontface = "bold", hjust = 0) +
  annotate("text", x = 29.5, y = 0.169,
           label = sprintf("Blitz rate vs. blitz payoff:\nr = %.2f (p = %.2f) — a flat line", r, pv),
           color = ink_primary, size = 3.1, hjust = 1, lineheight = 1) +
  scale_x_continuous(limits = c(-15, xcap + 1),
                     labels = function(v) paste0(ifelse(v > 0, "+", ""), v, "pp")) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                     limits = c(0.16, 0.365)) +
  scale_color_manual(values = c(`TRUE` = col_pays, `FALSE` = col_burn),
                     labels = c(`TRUE` = "Blitz pays vs. this QB",
                                `FALSE` = "Blitz costs EPA vs. this QB"),
                     name = NULL) +
  labs(
    title = "Defenses blitz on autopilot: blitz rates ignore which QBs the blitz beats",
    subtitle = paste0("A blitz buys ~12pp more pressure, but a failed blitz costs more than a failed 4-man rush — so it only\n",
                      "pays if the pressure bump clears a QB-specific break-even. Two-thirds of QBs cleared it in 2022-23,\n",
                      "yet how often coordinators blitzed each QB is unrelated to whether it paid."),
    x = "Blitz payoff: pressure-rate bump achieved minus bump needed to break even on EPA (percentage points)",
    y = "How often defenses blitzed this QB",
    caption = paste0("Data: nflverse play-by-play + FTN charting (blitz = n_blitzers > 0) + participation (was_pressure), 2022-23. Dropbacks only;\n",
                     "screens, spikes and missing-pressure plays excluded (36,779 plays). 38 QBs with 400+ dropbacks; per-QB EPA cells shrunk\n",
                     "to league means via empirical Bayes. Break-even solved from each QB's EPA with/without pressure vs. blitz and 4-man rush.\n",
                     "J.Allen (+58pp) capped at +30pp for display.")
  ) +
  theme_nfl() +
  theme(legend.position = c(0.87, 0.95),
        legend.background = element_blank(),
        legend.key.size = unit(0.9, "lines"))

save_chart(p, "blitz-autopilot")
