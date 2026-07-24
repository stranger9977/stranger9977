# =============================================================================
# Icing the kicker, done properly (2000-2025)
# Q: Does a defensive timeout immediately before a pressure FG reduce make prob?
#    Which coaches ice most, and does it work for anyone?
#
# Iced kick  : field_goal_attempt row whose immediately preceding row(s) in the
#              same game are standalone timeout rows, at least one charged to
#              the DEFENSE (walking back through contiguous timeout rows also
#              captures "double ices"; a timeout followed by any other snap
#              does NOT count — that timeout preceded a different play).
# Pressure   : half_seconds_remaining <= 120 (final 2:00 of either half) or OT,
#              AND score_differential in [-3, 0] (the kick ties or takes the
#              lead) — the situations where icing is actually deployed.
# Opportunity: pressure kick where the defense HAD a timeout to burn
#              (iced==1 | defteam_timeouts_remaining >= 1). All causal
#              comparisons run inside this sample to kill the
#              "icing correlates with having timeouts" confound.
# Controls   : ns(distance,4), EB-shrunk leave-one-out kicker quality,
#              indoor/wind/temp (+missing flag), era, situation
#              (end-H1 / end-game / OT), tie-vs-lead, final-40-seconds flag.
# =============================================================================
suppressMessages({library(data.table); library(splines); library(ggplot2)
                  library(scales); library(ggrepel)})
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")

SP <- "/tmp/claude-0/-home-user-stranger9977/f03221fa-fab0-55bd-bf7a-5b49b7ec5a63/scratchpad"
cache <- file.path(SP, "all_fg.rds")

# ---------------------------------------------------------------- extraction --
if (!file.exists(cache)) {
  cols <- c("game_id","play_id","season","qtr","half_seconds_remaining",
            "posteam","defteam","timeout","timeout_team","play_type","desc",
            "field_goal_attempt","field_goal_result","kick_distance",
            "kicker_player_name","kicker_player_id","score_differential",
            "roof","temp","wind","defteam_timeouts_remaining")
  res <- list()
  for (yr in 2000:2025) {
    d <- fread(sprintf("/home/user/stranger9977/nfl-analysis/data/play_by_play_%d.csv.gz", yr),
               select = cols, showProgress = FALSE)
    setorder(d, game_id, play_id)
    d[, rid := seq_len(.N)][, gstart := rid[1L], by = game_id]
    d[, to_row := as.integer(!is.na(timeout) & timeout == 1 & grepl("^\\s*Timeout", desc))]
    fg_idx <- d[field_goal_attempt == 1 & !is.na(kick_distance) &
                field_goal_result %in% c("made","missed","blocked"), rid]
    iced <- ndef <- integer(length(fg_idx))
    for (k in seq_along(fg_idx)) {                 # walk back over timeout rows
      i <- fg_idx[k]; j <- i - 1L; nd <- 0L
      while (j >= d$gstart[i] && d$to_row[j] == 1L) {
        if (!is.na(d$timeout_team[j]) && d$timeout_team[j] == d$defteam[i]) nd <- nd + 1L
        j <- j - 1L
      }
      ndef[k] <- nd; iced[k] <- as.integer(nd > 0L)
    }
    fg <- d[rid %in% fg_idx]
    fg[, `:=`(iced = iced, n_def_ice_timeouts = ndef, desc = NULL)]
    res[[as.character(yr)]] <- fg; rm(d); gc(verbose = FALSE)
  }
  saveRDS(rbindlist(res), cache)
}
fg <- readRDS(cache)
fg[, made := as.integer(field_goal_result == "made")]

# ------------------------------------------------- kicker quality (EB, LOO) --
base <- glm(made ~ ns(kick_distance, 5), data = fg, family = binomial)
fg[, exp_p := predict(base, newdata = fg, type = "response")]
fg[, resid := made - exp_p]
fg[, `:=`(k_sum = sum(resid), k_n = .N), by = kicker_player_id]
fg[, kq := (k_sum - resid) / (k_n - 1 + 60)]      # prior strength 60 attempts
fg[is.na(kicker_player_id) | kicker_player_id == "", kq := 0]

# ---------------------------------------------------------- pressure sample --
fg[, pressure := as.integer((half_seconds_remaining <= 120 | qtr >= 5) &
                            score_differential >= -3 & score_differential <= 0)]
fg[, situ := fifelse(qtr >= 5, "OT", fifelse(qtr <= 2, "end_H1", "end_game"))]
fg[, takes_lead := as.integer(score_differential > -3)]
fg[, era := cut(season, c(1999, 2005, 2012, 2019, 2025),
                labels = c("2000-05","2006-12","2013-19","2020-25"))]
pr <- fg[pressure == 1]
pr[, opp := as.integer(iced == 1 | defteam_timeouts_remaining >= 1)]
pr[, indoor := as.integer(roof %in% c("dome","closed"))]
pr[indoor == 1, `:=`(temp2 = 68, wind2 = 0)]
pr[indoor == 0, `:=`(temp2 = temp, wind2 = wind)]
pr[, wx_miss := as.integer(is.na(temp2) | is.na(wind2))]
pr[is.na(temp2), temp2 := median(pr$temp2, na.rm = TRUE)]
pr[is.na(wind2), wind2 := median(pr$wind2, na.rm = TRUE)]

opp <- pr[opp == 1]
cat(sprintf("Pressure kicks %d | opportunity sample %d (iced %d, not %d)\n",
            nrow(pr), nrow(opp), sum(opp$iced), sum(1 - opp$iced)))
cat(sprintf("Raw make (opp sample): iced %.3f vs not %.3f\n",
            opp[iced == 1, mean(made)], opp[iced == 0, mean(made)]))

# ----------------------------------------------------- model + marginal eff --
m <- glm(made ~ iced + ns(kick_distance, 4) + kq + indoor + wind2 + temp2 +
           wx_miss + era + situ + takes_lead + I(half_seconds_remaining <= 40),
         data = opp, family = binomial)
d1 <- copy(opp)[, iced := 1L]; d0 <- copy(opp)[, iced := 0L]
ame <- mean(predict(m, d1, type = "response")) -
       mean(predict(m, d0, type = "response"))
set.seed(42)
B  <- MASS::mvrnorm(2000, coef(m), vcov(m))
X1 <- model.matrix(delete.response(terms(m)), d1)
X0 <- model.matrix(delete.response(terms(m)), d0)
ames <- sapply(1:2000, function(b) mean(plogis(X1 %*% B[b,])) - mean(plogis(X0 %*% B[b,])))
ci <- quantile(ames, c(.025, .975))
cat(sprintf("AME of icing: %+.4f  [%.4f, %.4f]  (iced coef p=%.3f)\n",
            ame, ci[1], ci[2], summary(m)$coefficients["iced", 4]))

# trend: icing rate per opportunity by season (is the ritual dying?)
tr <- opp[, .(rate = mean(iced), n = .N), by = season]
cat(sprintf("Icing rate per opportunity: 2000-05 %.2f | 2020-25 %.2f | OLS slope/yr %+0.4f\n",
            opp[season <= 2005, mean(iced)], opp[season >= 2020, mean(iced)],
            coef(lm(rate ~ season, tr))[2]))

# ---------------------------------------------------------- CHART 1: effect --
grid <- CJ(kick_distance = 20:58, iced = c(0L, 1L))
grid[, `:=`(kq = 0, indoor = 0, wind2 = median(opp$wind2), temp2 = median(opp$temp2),
            wx_miss = 0, era = factor("2020-25", levels = levels(opp$era)),
            situ = "end_game", takes_lead = 1L, half_seconds_remaining = 60)]
pgrid <- predict(m, grid, type = "link", se.fit = TRUE)
grid[, `:=`(p = plogis(pgrid$fit), lo = plogis(pgrid$fit - 1.96 * pgrid$se.fit),
            hi = plogis(pgrid$fit + 1.96 * pgrid$se.fit))]
grid[, Kick := fifelse(iced == 1, "Iced", "Not iced")]

bins <- opp[kick_distance >= 20 & kick_distance < 60,
            .(p = mean(made), n = .N, d = mean(kick_distance)),
            by = .(b = 5 * floor(kick_distance / 5), iced)]
bins[, Kick := fifelse(iced == 1, "Iced", "Not iced")]

ann <- sprintf("Adjusted effect of icing:\n%+.1f pts of make probability\n95%% CI [%.1f, %+.1f]",
               100 * ame, 100 * ci[1], 100 * ci[2])
p1 <- ggplot(grid, aes(kick_distance, p, color = Kick, fill = Kick)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = .13, color = NA) +
  geom_line(linewidth = 1.1) +
  geom_point(data = bins, aes(d, p, size = n), alpha = .55) +
  annotate("label", x = 22, y = .40, label = ann, hjust = 0, size = 3.4,
           color = ink_primary, fill = col_surface, label.size = 0,
           fontface = "bold", lineheight = 1.05) +
  scale_color_manual(values = c("Iced" = pal_cat[2], "Not iced" = pal_cat[1])) +
  scale_fill_manual(values = c("Iced" = pal_cat[2], "Not iced" = pal_cat[1])) +
  scale_size_area(max_size = 6, guide = "none") +
  scale_y_continuous(labels = percent_format(1), limits = c(.30, 1)) +
  labs(title = "Icing the kicker shaves ~3 pts off makes — but 26 seasons can't prove it",
       subtitle = "Adjusted make probability on pressure FGs (final 2:00 of a half or OT, kick ties or takes the lead),\nby whether the defense called timeout right before the snap. Dots = raw 5-yd bins, sized by attempts.",
       x = "Kick distance (yards)", y = "Make probability",
       color = NULL, fill = NULL,
       caption = paste("nflverse pbp 2000-2025. 2,221 pressure FGs; comparison inside the 1,782 where the defense had a timeout to burn (585 iced, 1,197 not).",
                       "Controls: distance spline, EB-shrunk kicker quality (leave-one-out), indoor/wind/temp, era, end-H1 vs end-game vs OT, tie vs go-ahead.",
                       "Icing rate per opportunity has hovered near 33% all 26 seasons (35% in 2000-05, 29% in 2020-25) — the ritual is not dying out.",
                       sep = "\n")) +
  theme_nfl() + theme(legend.position = c(.85, .88))
save_chart(p1, "icing-the-kicker")

# ------------------------------------------------- CHART 2: coach funnel -----
g <- fread("/home/user/stranger9977/nfl-analysis/data/games.csv",
           select = c("game_id","home_team","away_team","home_coach","away_coach"))
setnames(g, c("home_team","away_team"), c("home_g","away_g"))
pr <- merge(pr, g, by = "game_id", all.x = TRUE)
pr[, def_coach := fifelse(defteam == home_g, home_coach, away_coach)]

# icing frequency leaderboard (min 15 opportunities)
co <- pr[opp == 1, .(opps = .N, ice_rate = mean(iced)), by = def_coach][opps >= 15]
cat("\nTop icers:\n"); print(head(co[order(-ice_rate)], 5))
cat("Bottom icers:\n"); print(head(co[order(ice_rate)], 3))

# per-coach icing "effect": observed iced make rate minus model-expected had the
# same kicks NOT been iced (model refit on all pressure kicks for prediction)
m2 <- update(m, data = pr)
prn <- copy(pr)[, iced := 0L]
pr[, exp_noice := predict(m2, prn, type = "response")]
ce <- pr[iced == 1 & opp == 1,
         .(n_iced = .N, eff = mean(made) - mean(exp_noice)), by = def_coach][n_iced >= 8]
ce <- merge(ce, co[, .(def_coach, ice_rate)], by = "def_coach", all.x = TRUE)
pbar <- pr[iced == 1 & opp == 1, mean(exp_noice)]         # cone reference p
cone <- data.table(n = seq(6, max(ce$n_iced) + 2, .5))
cone[, se := sqrt(pbar * (1 - pbar) / n)]
n_out <- ce[abs(eff) > 1.96 * sqrt(pbar * (1 - pbar) / n_iced), .N]
cat(sprintf("Coaches outside 95%% cone: %d of %d (chance predicts ~%.1f)\n",
            n_out, nrow(ce), .05 * nrow(ce)))
print(ce[order(eff)])

p2 <- ggplot(ce, aes(n_iced, eff)) +
  geom_ribbon(data = cone, aes(n, ymin = -1.96 * se, ymax = 1.96 * se),
              inherit.aes = FALSE, fill = col_grid, alpha = .55) +
  geom_hline(yintercept = 0, color = col_baseline) +
  geom_point(aes(fill = ice_rate), shape = 21, size = 3.4, color = col_surface, stroke = .6) +
  geom_text_repel(aes(label = def_coach), size = 3.0, color = ink_secondary,
                  seed = 7, max.overlaps = 30, box.padding = .32, segment.color = col_baseline) +
  scale_fill_gradient(low = pal_seq[1], high = pal_seq[7],
                      labels = percent_format(1), name = "Ices this % of\nhis chances") +
  scale_y_continuous(labels = function(x) sprintf("%+.0f pp", 100 * x)) +
  scale_x_continuous(breaks = seq(8, 24, 4)) +
  labs(title = "No coach owns the ice: 20 of 21 icing 'effects' sit inside the noise cone",
       subtitle = "Iced-kick make rate minus model expectation had those kicks not been iced (min 8 iced pressure kicks).\nGray cone = 95% band of pure binomial luck. One outlier out of 21 is exactly what chance predicts.",
       x = "Career iced pressure kicks (as defensive head coach)",
       y = "Make rate vs expectation on his iced kicks",
       caption = paste("nflverse pbp 2000-2025; defensive head coach from nflverse games. Expectation from the logistic model with distance,",
                       "kicker-quality, weather, era, situation controls. Heaviest icers per chance (min 15 opps): LaFleur 67%, Crennel 65%,",
                       "McDermott 63%, Shanahan 60%; lightest: Holmgren 12%, Vrabel 12%, Carroll 21%.", sep = "\n")) +
  theme_nfl() + theme(legend.position = c(.93, .78))
save_chart(p2, "icing-coach-funnel")
