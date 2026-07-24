# Timeout discipline: which head coaches waste timeouts, 2000-2025.
#
# Two measurable sins, attributed to the head coach via games.csv:
#   1. BURNING them early  — charged offensive timeouts taken before the final
#      4:00 of a half (the classic delay-of-game bailout), per game, vs the
#      league average that season (burn rate drifted from ~0.98/gm in 2000 to
#      ~0.62/gm in 2025, so era-adjustment is required). Injury TOs excluded.
#   2. DYING with them late — one-score regulation losses (trailing by 1-8 at
#      the 2:00 mark of Q4) that end with 1+ timeout unused. League avg: 15%.
#
# Finding: Mike Martz burned 2.0 early offensive TOs per game (+1.02 vs his
# era, every season of his career); Norv Turner died holding timeouts in 11 of
# 31 close losses (35%, p = 0.003 vs league). Mike Shanahan is the only coach
# in the bottom 8 of BOTH components; Herm Edwards is top-8 in both. Andy
# Reid, the most-mocked clock manager alive, almost never dies with them
# (4/61, best big-sample rate).

library(data.table)
library(ggplot2)
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")

DATA <- "/home/user/stranger9977/nfl-analysis/data"

# ---- 1. Extract timeout events + end-of-game state, season by season -------
# Timeout rows in nflfastR are standalone no_play rows with blank posteam, so
# the side of ball is inferred from the next snap's posteam (backward fill).
locf <- function(x) {                       # last-obs-carried-forward, char
  ok <- !is.na(x); i <- cumsum(ok)
  y <- x[ok][pmax(i, 1)]; y[i == 0] <- NA_character_; y
}

cols <- c("game_id", "play_id", "qtr", "half_seconds_remaining",
          "game_seconds_remaining", "timeout", "timeout_team", "posteam",
          "posteam_timeouts_remaining", "defteam_timeouts_remaining",
          "score_differential", "desc", "home_team", "away_team")

out <- vector("list", 26)
for (yr in 2000:2025) {
  d <- fread(sprintf("%s/play_by_play_%d.csv.gz", DATA, yr),
             select = cols, showProgress = FALSE)
  setorder(d, game_id, play_id)
  d[posteam == "", posteam := NA_character_]
  d[, pos_next := rev(locf(rev(posteam))), by = game_id]

  # charged team timeouts, classified offensive/defensive + early
  to <- d[timeout == 1 & !is.na(timeout_team) & timeout_team != "",
          .(game_id, qtr, half_seconds_remaining, timeout_team, pos_next,
            injury = grepl("njury", desc))]
  tg <- to[, .(burns_off_early = sum(timeout_team == pos_next &
                 half_seconds_remaining > 240 & qtr <= 4 & !injury, na.rm = TRUE)),
           by = .(game_id, team = timeout_team)]

  # timeouts remaining at the final snap of the game, per team
  eg <- d[!is.na(posteam) & !is.na(posteam_timeouts_remaining) &
            !is.na(defteam_timeouts_remaining),
          .SD[.N, .(qtr_end = qtr, posteam,
                    pos_to = posteam_timeouts_remaining,
                    def_to = defteam_timeouts_remaining)], by = game_id]

  # score margin at the last snap before 2:00 of Q4
  m2 <- d[qtr == 4 & game_seconds_remaining >= 120 & !is.na(posteam) &
            !is.na(score_differential),
          .SD[.N, .(pos2 = posteam, sd_2min = score_differential)], by = game_id]

  teams <- d[, .(home = home_team[1], away = away_team[1]), by = game_id]
  x <- rbind(teams[, .(game_id, team = home)], teams[, .(game_id, team = away)])
  x <- merge(x, tg, by = c("game_id", "team"), all.x = TRUE)
  x[is.na(burns_off_early), burns_off_early := 0L]
  x <- merge(x, eg, by = "game_id", all.x = TRUE)
  x[, to_end := fifelse(team == posteam, pos_to, def_to)]
  x <- merge(x[, .(game_id, team, burns_off_early, qtr_end, to_end)],
             m2, by = "game_id", all.x = TRUE)
  x[, margin_2min := fifelse(team == pos2, sd_2min, -sd_2min)][, c("pos2", "sd_2min") := NULL]
  x[, season := yr]
  out[[yr - 1999]] <- x
  rm(d, to, tg, eg, m2, teams, x); gc(verbose = FALSE)
}
tg <- rbindlist(out)

# ---- 2. Attach head coaches and results (games.csv) ------------------------
g <- fread(file.path(DATA, "games.csv"),
           select = c("game_id", "season", "home_team", "away_team",
                      "home_score", "away_score", "home_coach", "away_coach"))
g <- g[season >= 2000 & season <= 2025 & !is.na(home_score)]
fix <- function(x) fcase(x == "STL", "LA", x == "SD", "LAC", x == "OAK", "LV",
                         rep(TRUE, length(x)), x)   # pbp uses current codes
g[, `:=`(home_team = fix(home_team), away_team = fix(away_team))]
gl <- rbind(g[, .(game_id, team = home_team, pts = home_score,
                  opp_pts = away_score, coach = home_coach)],
            g[, .(game_id, team = away_team, pts = away_score,
                  opp_pts = home_score, coach = away_coach)])
tg <- merge(tg, gl, by = c("game_id", "team"))          # 14,030 team-games
stopifnot(nrow(tg) == 14030)

tg[, margin := pts - opp_pts]
tg[, close_trail_loss := !is.na(margin_2min) & margin_2min <= -1 &
     margin_2min >= -8 & margin < 0 & qtr_end <= 4]
tg[, died := as.integer(close_trail_loss & !is.na(to_end) & to_end >= 1)]
tg[, exp_burn := mean(burns_off_early), by = season]     # era adjustment

# ---- 3. Coach leaderboards -------------------------------------------------
co <- tg[, .(n_games = .N, last = max(season),
             burn_pg = mean(burns_off_early),
             burn_vs = mean(burns_off_early - exp_burn),
             n_ctl = sum(close_trail_loss), died_n = sum(died)),
         by = coach]
co[, died_rate := died_n / pmax(n_ctl, 1)]
co[, cur := last >= 2024]

A <- co[n_games >= 80]                 # burn panel: 65 coaches qualify
B <- co[n_games >= 80 & n_ctl >= 20]   # died panel: 33 coaches qualify
cat("League died-with-TO rate:",
    round(tg[close_trail_loss == TRUE, mean(died)], 3), "\n")

pick <- function(dt, val, k = 8) {
  setorderv(dt, val)
  rbind(dt[1:k][, grp := "best"], dt[(.N - k + 1):.N][, grp := "worst"])
}
pa <- pick(copy(A), "burn_vs")
pb <- pick(copy(B), "died_rate")
pa[, `:=`(panel = "1. BURNING THEM EARLY (per game vs league average)",
          value = burn_vs,
          lab = sprintf("%+.2f", burn_vs),
          nm  = sprintf("%s%s  (%d gms)", coach, fifelse(cur, "*", ""), n_games))]
pb[, `:=`(panel = "2. DYING WITH THEM LATE (share of close losses)",
          value = died_rate,
          lab = sprintf("%.0f%%  (%d/%d)", 100 * died_rate, died_n, n_ctl),
          nm  = sprintf("%s%s  (%d gms)", coach, fifelse(cur, "*", ""), n_games))]

pd <- rbind(pa[, .(panel, nm, value, lab, grp)], pb[, .(panel, nm, value, lab, grp)])
pd[, ord := paste(panel, formatC(frank(value, ties.method = "first"),
                                 width = 3, flag = "0")), by = panel]
pd[, ord := factor(ord, levels = sort(unique(ord)))]

print(pd[order(panel, -value), .(panel = substr(panel, 1, 10), nm, lab, grp)],
      nrows = 40)   # verify every number that lands on the chart

# ---- 4. Chart --------------------------------------------------------------
ref <- data.table(panel = unique(pd$panel)[2],
                  x = tg[close_trail_loss == TRUE, mean(died)])

p <- ggplot(pd, aes(x = value, y = ord, fill = grp)) +
  geom_vline(xintercept = 0, color = col_baseline, linewidth = 0.4) +
  geom_vline(data = ref, aes(xintercept = x), linetype = "22",
             color = ink_muted, linewidth = 0.4) +
  geom_col(width = 0.62, alpha = 0.92) +
  geom_text(aes(label = lab, hjust = fifelse(value >= 0, -0.12, 1.12)),
            size = 3.05, color = ink_primary, fontface = "bold") +
  geom_text(data = ref, aes(x = x, y = 15.5, label = "league 15%"),
            inherit.aes = FALSE, size = 2.9, color = ink_muted, hjust = -0.08) +
  scale_y_discrete(labels = setNames(pd$nm, as.character(pd$ord))) +
  scale_x_continuous(expand = expansion(mult = c(0.16, 0.30))) +
  scale_fill_manual(values = c(best = pal_div$low, worst = pal_div$high),
                    guide = "none") +
  facet_wrap(~panel, scales = "free") +
  labs(
    title = "The two ways to waste a timeout: Mike Martz burned them, Norv Turner died with them",
    subtitle = "Head-coach timeout discipline, 2000-2025. Left: offensive timeouts taken before the last 4:00 of a half (the delay-of-game bailout), per game vs the league rate that\nseason. Right: share of losses (trailing by 1-8 at the Q4 two-minute mark) finished with a timeout still in the pocket. Worst 8 in red, best 8 in blue; middle folded.",
    x = NULL, y = NULL,
    caption = paste0(
      "nflfastR pbp + games.csv, 2000-2025 incl. playoffs; timeouts attributed to the head coach | * = active head coach in 2024-25\n",
      "Burned: charged offensive TOs with >4:00 left in a half (injury TOs excluded), vs season league mean (0.98/gm in 2000 down to 0.62 in 2025); min 80 games, 65 qualify. Martz: 2.02/gm raw, 2x league in all 6 seasons.\n",
      "Died: regulation losses, trailing 1-8 at Q4 2:00, ending with 1+ TO unused; league 15%, no era trend; min 20 such losses, 33 qualify. Norv Turner 11/31: p = 0.003 vs league.\n",
      "Mike Shanahan is the only coach in the worst 8 of BOTH panels; Herm Edwards (9%, 2/23) is top-8 in both. Companion analysis prices a banked timeout at ~0.08 pts when a two-minute drill arises."
    )
  ) +
  theme_nfl(base_size = 12.5) +
  theme(strip.text = element_text(color = ink_secondary, face = "bold",
                                  size = 9.5, hjust = 0),
        axis.text.y = element_text(color = ink_primary, size = 8.6),
        axis.text.x = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.subtitle = element_text(size = 9.8),
        plot.caption = element_text(lineheight = 1.25, size = 7.6),
        panel.spacing.x = unit(1.6, "lines"))

save_chart(p, "timeout_discipline", width = 12.6, height = 7.2)
