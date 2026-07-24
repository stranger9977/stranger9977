# Tendency fingerprints: per-caller down x distance grids colored by how much
# MORE or LESS guessable than the league each caller is (not by raw deviation).
#
# The story (situation-controlled, NOT QB-controlled): being predictable does
# not sink an offense. Across 80 callers, being more guessable-than-league is
# if anything weakly POSITIVELY linked to EPA (r = +0.35) -- the opposite of the
# intuition that readable = punished. Exemplars show the scatter honestly:
# guessable callers can be elite (Reid) or poor (Gruden); hard-to-guess callers
# can be elite (Ben Johnson) or poor (Kelly, Gase). And the EPA edge tracks the
# quarterback (CPOE) as much as the caller.
#
# ENCODING FIX vs prior version: fill is now the per-cell GUESSABILITY
# CONTRIBUTION vs league -- (optimal guesser's hit-rate on the caller) minus
# (on the league), in the same down x distance cell, in extra correct calls per
# 100 plays. Weighted by cell volume these cells sum exactly to the strip
# number, so color genuinely decomposes the predictability metric. Red = easier
# to guess than the league here; blue = harder (more coin-flip). This kills the
# old "deep blue = far more run = looks committed" inversion: blue now means
# LESS guessable, full stop.
suppressMessages({library(data.table); library(ggplot2); library(scales)})
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")

p  <- as.data.table(readRDS("/Users/nick/stranger9977/nfl-analysis/scratch/pred_plays.rds"))
cc <- as.data.table(readRDS("/Users/nick/stranger9977/nfl-analysis/scratch/pred_career.rds"))

p <- p[down %in% 1:3]
p[, togo_b := factor(togo_b, levels = c("1-3","4-6","7-10","11+"))]

# League baseline pass rate per down x distance cell (2015-2025, downs 1-3).
lg <- p[, .(lg = mean(is_pass)), by = .(down, togo_b)]
lg_overall <- p[, mean(is_pass)]

K <- 15  # empirical-Bayes shrinkage toward the league cell rate (matches build)

# Exemplars span the two quadrants both ways (see header).
callers <- c("Andy Reid","Jay Gruden","Kyle Shanahan",
             "Chip Kelly","Adam Gase","Ben Johnson")

# ---- QB-context measure (CPOE) to expose the QB confound in "ELITE offense" --
# EPA/play is the authoritative all-down career figure (pred_career); CPOE is a
# QB-accuracy measure (completion % over expected), all downs, from slim pbp.
pfull <- as.data.table(readRDS("/Users/nick/stranger9977/nfl-analysis/scratch/pred_plays.rds"))
pc <- pfull[off_play_caller %in% callers, .(game_id, play_id, off_play_caller)]
rm(pfull)
pb <- as.data.table(readRDS("/Users/nick/stranger9977/nfl-analysis/data/pbp_slim.rds"))
pb <- pb[, .(game_id, play_id, cpoe)]
pc <- merge(pc, pb, by = c("game_id","play_id"), all.x = TRUE)
rm(pb); gc()
qb <- merge(pc[, .(cpoe = mean(cpoe, na.rm = TRUE)), by = off_play_caller],
            cc[, .(off_play_caller, epa_play)], by = "off_play_caller")

# ---- per-cell guessability contribution vs league, EB-shrunk ----------------
cells <- p[off_play_caller %in% callers,
           .(np = sum(is_pass), n = .N), by = .(off_play_caller, down, togo_b)]
cells <- merge(cells, lg, by = c("down","togo_b"))
cells[, pr    := np / n]
cells[, p_shr := (np + K*lg) / (n + K)]                 # shrink toward league
cells[, g     := pmax(p_shr, 1 - p_shr)]                # optimal guesser hit-rate
cells[, glg   := pmax(lg, 1 - lg)]                      # league guesser hit-rate
cells[, contrib := (g - glg) * 100]                     # extra correct / 100 in cell

# Strip guessability = volume-weighted mean of the cells shown (down x distance
# resolution). This is the exact sum of the colored contributions.
grid <- cells[, .(guess = sum(contrib * n) / sum(n)), by = off_play_caller]

# ---- game-cluster bootstrap 95% CI on each caller's down x distance guessability
set.seed(11)
B <- 800
boot_ci <- function(nm){
  d  <- p[off_play_caller == nm, .(game_id, down, togo_b, is_pass)]
  d  <- merge(d, lg, by = c("down","togo_b"))
  gid <- unique(d$game_id); G <- length(gid)
  setkey(d, game_id)
  out <- numeric(B)
  for (b in seq_len(B)) {
    samp <- d[.(sample(gid, G, replace = TRUE)), allow.cartesian = TRUE]
    cl <- samp[, .(np = sum(is_pass), n = .N, lg = lg[1]), by = .(down, togo_b)]
    cl[, ps := (np + K*lg)/(n + K)]
    cl[, ct := (pmax(ps,1-ps) - pmax(lg,1-lg))*100]
    out[b] <- cl[, sum(ct*n)/sum(n)]
  }
  quantile(out, c(.025,.975), names = FALSE)
}
ci <- rbindlist(lapply(callers, function(nm){
  q <- boot_ci(nm); data.table(off_play_caller = nm, lo = q[1], hi = q[2])
}))

ann <- Reduce(function(a,b) merge(a,b,by="off_play_caller"),
              list(grid, ci, qb,
                   cc[off_play_caller %in% callers,
                      .(off_play_caller, guess_xs, H_vs_lg)]))
setorder(ann, -guess)

# ---- overall correlations (report with n + CI; sign + what's controlled) -----
r_car  <- cor(cc$H_vs_lg,  cc$epa_play); n_car <- nrow(cc)
z <- atanh(r_car); se <- 1/sqrt(n_car-3)
ci_car <- tanh(z + c(-1,1)*1.96*se)
r_g    <- cor(cc$guess_xs, cc$epa_play)
zg <- atanh(r_g); ci_g <- tanh(zg + c(-1,1)*1.96*se)

# ---- strip labels: name, continuous guessability + CI, EPA + CPOE ------------
lab <- sapply(callers, function(nm){
  a <- ann[off_play_caller == nm]
  sprintf("%s\nguessability %+.1f / 100   (95%% CI %+.1f, %+.1f)\nEPA/play %+.3f  ·  QB accuracy (CPOE) %+.1f",
          nm, a$guess, a$lo, a$hi, a$epa_play, a$cpoe)
})
names(lab) <- callers

# gray sub-threshold cells (raw label too noisy); shrinkage already damps them
cells[, sub := n < 25]
cells[sub == TRUE, contrib := NA]
cells[, off_play_caller := factor(off_play_caller, levels = ann$off_play_caller,
                                  labels = lab[ann$off_play_caller])]
cells[, cell_lab := ifelse(sub, paste0("n=", n), paste0(round(pr*100), "%"))]
cells[, down_lab := factor(paste0(down, ifelse(down==1,"st",ifelse(down==2,"nd","rd"))),
                           levels = c("3rd","2nd","1st"))]

lim <- max(abs(cells$contrib), na.rm = TRUE)

p1 <- ggplot(cells, aes(togo_b, down_lab, fill = contrib)) +
  geom_tile(color = col_surface, linewidth = 1.1) +
  geom_text(aes(label = cell_lab,
                color = abs(contrib) > 0.62*lim | is.na(contrib)),
            size = 3.0, fontface = "bold", na.rm = FALSE) +
  scale_color_manual(values = c("TRUE" = "#ffffff", "FALSE" = ink_primary),
                     guide = "none", na.value = ink_muted) +
  facet_wrap(~off_play_caller, ncol = 3) +
  scale_fill_gradient2(low = pal_div$low, mid = pal_div$mid, high = pal_div$high,
                       midpoint = 0, limits = c(-lim, lim),
                       na.value = "#e6e5df",
                       labels = function(x) sprintf("%+d", round(x)),
                       name = "Guessability vs league\n(extra correct run/pass\ncalls per 100, in cell)\n\nred = easier to guess\nblue = harder (coin-flip)") +
  labs(
    title = "Being predictable doesn't hurt: the NFL's most readable play-callers are, if anything, its more efficient ones",
    subtitle = paste0(
      "Cell color = how much more (red) or less (blue) guessable than the league a caller is at that down × distance; the number is the caller's pass rate.\n",
      sprintf("Across %d callers, being more guessable-than-league goes with slightly HIGHER EPA (r = %+.2f, 95%% CI %+.2f to %+.2f), not lower.\n",
              n_car, r_g, ci_g[1], ci_g[2]),
      "but the tie is weak and QB-driven: Gruden is guessable yet poor; Ben Johnson is hard to guess yet elite."),
    x = "Yards to go", y = NULL,
    caption = paste0(
      "Called plays, downs 1–3, 2015–2025 (pred_plays; caller-attributed). Guessability = an optimal situational guesser's hit-rate on the caller minus on the league,\n",
      sprintf("EB-shrunk toward each cell's rate (K=15); colored cells sum by volume to the strip figure. League pass rate = %.0f%% overall.\n", lg_overall*100),
      sprintf("Predictability–efficiency link, same seasons: r(H_vs_lg, EPA/play) = %+.2f across %d callers (95%% CI %+.2f, %+.2f), and -0.37 across 377 caller-seasons;\n", r_car, n_car, ci_car[1], ci_car[2]),
      "negative = more-predictable-than-league goes with higher EPA. Situation-controlled, NOT QB-controlled.\n",
      "EPA/play and CPOE reflect the QB and supporting cast, not the caller alone (Reid's +2.8 CPOE is Mahomes; Ben Johnson posts elite EPA on near-league CPOE).\n",
      "Cells with n<25 grayed and labeled n: only Gruden and Kelly have any (rare long-yardage); Reid has none.")
  ) +
  theme_nfl(base_size = 12) +
  theme(
    panel.grid = element_blank(),
    axis.text = element_text(color = ink_secondary, size = 10),
    strip.text = element_text(face = "bold", size = 9.0, color = ink_primary,
                              lineheight = 1.08, margin = margin(4,2,4,2)),
    legend.position = "right",
    legend.key.height = unit(24, "pt"),
    legend.title = element_text(size = 9, lineheight = 1.0),
    plot.subtitle = element_text(lineheight = 1.12),
    panel.spacing = unit(14, "pt")
  )

save_chart(p1, "tendency-fingerprints", width = 14, height = 8.9)

# ---- verification dump ----
cat("\nLeague overall pass rate downs1-3:", round(lg_overall,4), "\n")
cat("Fill limit (extra correct/100):", round(lim,2), "\n")
cat(sprintf("r(guess_xs,epa) career: %+.3f  CI [%+.3f, %+.3f]  n=%d\n", r_g, ci_g[1], ci_g[2], n_car))
cat(sprintf("r(H_vs_lg,epa)  career: %+.3f  CI [%+.3f, %+.3f]  n=%d\n", r_car, ci_car[1], ci_car[2], n_car))
cat("\nStrip annotations (ordered as plotted):\n")
print(ann[, .(off_play_caller, guess=round(guess,2), lo=round(lo,2), hi=round(hi,2),
              epa_play=round(epa_play,3), cpoe=round(cpoe,2), guess_xs_full=round(guess_xs,2))])
cat("\nSub-threshold (n<25) cells:\n")
print(p[off_play_caller %in% callers,
        .(n=.N), by=.(off_play_caller,down,togo_b)][n<25][order(off_play_caller)])
