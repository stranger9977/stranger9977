# Pedigree half-life: when does a rookie WR's on-field usage make his draft slot obsolete?
#
# For WRs drafted 2011-2022, we track two competing predictors of years-2-3 production
# (REG receiving yards per season in draft year +1/+2, zero if out of the league):
#   1) cumulative share of team targets through rookie-season week W (W = 1..12)
#   2) draft capital, log(overall pick)
# For each week W we fit  outcome ~ cum_target_share_W + log(pick)  and record each
# predictor's partial R^2 (variance uniquely explained controlling for the other).
# Wrinkle: usage is decomposed into weeks the team's WR1 was active vs. out, testing
# whether injury-inflated rookie target share is a false-positive talent signal.

library(data.table)
library(ggplot2)
library(scales)
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")

## ---- data -------------------------------------------------------------------
ps <- fread("/home/user/stranger9977/nfl-analysis/data/player_stats.csv.gz",
            select = c("player_id","player_display_name","position","recent_team","season",
                       "week","season_type","targets","receiving_yards","fantasy_points_ppr"))
ps <- ps[season_type == "REG"]
ps[is.na(targets), targets := 0]

dp <- fread("/home/user/stranger9977/nfl-analysis/data/draft_picks.csv")
wr <- dp[position == "WR" & season >= 2011 & season <= 2022 & !is.na(gsis_id) & gsis_id != "",
         .(gsis_id, draft_season = season, round, pick, pfr_player_name)]

teamwk <- ps[, .(team_targets = sum(targets)), by = .(recent_team, season, week)]

rk   <- merge(ps, wr, by.x = "player_id", by.y = "gsis_id")
rook <- rk[season == draft_season]

## cohort: >=4 REG appearances in rookie weeks 1-8 (excludes redshirt/IR rookies)
appear <- rook[week <= 8, .(games18 = .N), by = player_id]
cohort <- merge(wr, appear, by.x = "gsis_id", by.y = "player_id")[games18 >= 4]

## rookie's team = modal team over weeks 1-8
rteam  <- rook[week <= 8, .N, by = .(player_id, recent_team)][order(-N)][, .SD[1], by = player_id]
cohort <- merge(cohort, rteam[, .(player_id, rteam = recent_team)],
                by.x = "gsis_id", by.y = "player_id")

## team WR1 = non-focal WR with most REG targets on rookie's team that season (>=20 tgts)
wrsz <- ps[position == "WR", .(tot = sum(targets)), by = .(player_id, season, recent_team)]
get_wr1 <- function(pid, tm, ssn) {
  cand <- wrsz[season == ssn & recent_team == tm & player_id != pid][order(-tot)]
  if (nrow(cand) == 0 || cand$tot[1] < 20) return(NA_character_)
  cand$player_id[1]
}
cohort[, wr1 := mapply(get_wr1, gsis_id, rteam, draft_season)]

## weeks WR1 was active (has a weekly stat row)
wr1wk <- merge(cohort[!is.na(wr1), .(gsis_id, wr1, draft_season)],
               ps[, .(player_id, season, week)],
               by.x = c("wr1","draft_season"), by.y = c("player_id","season"),
               allow.cartesian = TRUE)
wr1wk <- unique(wr1wk[, .(gsis_id, week, wr1_active = 1L)])

## rookie x team-week panel, weeks 1-12
tw <- merge(cohort[, .(gsis_id, rteam, draft_season)],
            teamwk[week <= 12], by.x = c("rteam","draft_season"),
            by.y = c("recent_team","season"), allow.cartesian = TRUE)
tw <- merge(tw, rook[, .(player_id, week, ptargets = targets)],
            by.x = c("gsis_id","week"), by.y = c("player_id","week"), all.x = TRUE)
tw[is.na(ptargets), ptargets := 0]
tw <- merge(tw, wr1wk, by = c("gsis_id","week"), all.x = TRUE)
tw[is.na(wr1_active), wr1_active := 0L]

## cumulative target share through each week W (and WR1-active / WR1-out split at W=8)
cum <- rbindlist(lapply(1:12, function(Wk) {
  tw[week <= Wk, .(W = Wk,
                   cts   = sum(ptargets) / pmax(sum(team_targets), 1),
                   a_num = sum(ptargets[wr1_active == 1]),
                   a_den = sum(team_targets[wr1_active == 1]),
                   o_num = sum(ptargets[wr1_active == 0]),
                   o_den = sum(team_targets[wr1_active == 0])),
     by = gsis_id]
}))

## outcome: years 2-3 receiving yards per season (0 if absent from the league)
y23 <- rk[season %in% c(draft_season + 1, draft_season + 2),
          .(y_yds = sum(receiving_yards), g = .N, ppr = sum(fantasy_points_ppr)), by = player_id]
cohort <- merge(cohort, y23, by.x = "gsis_id", by.y = "player_id", all.x = TRUE)
cohort[is.na(y_yds), `:=`(y_yds = 0, g = 0, ppr = 0)]
cohort[, `:=`(yps = y_yds / 2, ppg = ifelse(g > 0, ppr / g, 0), lpick = log(pick))]

## ---- week-by-week partial R^2 ----------------------------------------------
wide <- dcast(cum, gsis_id ~ W, value.var = "cts")
setnames(wide, as.character(1:12), paste0("cts_", 1:12))
wide <- merge(wide, cohort[, .(gsis_id, yps, ppg, lpick, draft_season)], by = "gsis_id")
wide[is.na(wide)] <- 0   # week-1 byes: no team game yet -> share 0

pr2_pair <- function(d, Wk, yvar = "yps") {
  x <- d[[paste0("cts_", Wk)]]; y <- d[[yvar]]; p <- d$lpick
  sse  <- function(m) sum(resid(m)^2)
  full <- lm(y ~ x + p); nox <- lm(y ~ p); nop <- lm(y ~ x)
  c(ts = (sse(nox) - sse(full)) / sse(nox), pick = (sse(nop) - sse(full)) / sse(nop))
}

res <- rbindlist(lapply(1:12, function(Wk) {
  pr <- pr2_pair(wide, Wk)
  data.table(W = Wk, pr2_ts = pr["ts"], pr2_pick = pr["pick"])
}))

## bootstrap (resample players; whole curve per draw -> CIs + crossover distribution)
set.seed(42)
B <- 500
boot <- rbindlist(lapply(1:B, function(b) {
  d <- wide[sample(.N, .N, replace = TRUE)]
  rbindlist(lapply(1:12, function(Wk) {
    pr <- pr2_pair(d, Wk)
    data.table(b = b, W = Wk, pr2_ts = pr["ts"], pr2_pick = pr["pick"])
  }))
}))
ci <- boot[, .(ts_lo = quantile(pr2_ts, .1), ts_hi = quantile(pr2_ts, .9),
               pk_lo = quantile(pr2_pick, .1), pk_hi = quantile(pr2_pick, .9)), by = W]
res <- merge(res, ci, by = "W")
cross_dist <- boot[, .(cross = {w <- W[pr2_ts > pr2_pick]
                                if (length(w)) min(w) else NA_integer_}), by = b]
cross_wk   <- res[pr2_ts > pr2_pick, min(W)]
cat("crossover week:", cross_wk, " | bootstrap 10-90%:",
    quantile(cross_dist$cross, c(.1, .9), na.rm = TRUE), " | no-crossover draws:", sum(is.na(cross_dist$cross)), "\n")

## robustness: era split + PPG outcome at week 8
for (era in list(2011:2016, 2017:2022)) {
  pr <- pr2_pair(wide[draft_season %in% era], 8)
  cat("era", era[1], "-", era[length(era)], "n =", nrow(wide[draft_season %in% era]),
      " pr2_ts =", round(pr["ts"], 3), " pr2_pick =", round(pr["pick"], 3), "\n")
}
cat("PPR PPG outcome, week 8:", round(pr2_pair(wide, 8, "ppg"), 3), "\n")

## injury false-positive test: rookies with >=1 game's worth of targets both with
## WR1 active and WR1 out through week 8
inj <- merge(cum[W == 8 & a_den >= 30 & o_den >= 30], cohort, by = "gsis_id")
inj[, `:=`(ts_a = a_num / a_den, ts_o = o_num / o_den)]
mi <- summary(lm(scale(yps) ~ scale(ts_a) + scale(ts_o) + scale(lpick), inj))$coefficients
cat("injury split n =", nrow(inj), "\n"); print(round(mi, 3))

## ---- chart ------------------------------------------------------------------
col_ts <- pal_cat[1]; col_pk <- pal_cat[2]
long <- melt(res[, .(W, `Rookie target share` = pr2_ts, `Draft slot` = pr2_pick)],
             id.vars = "W", variable.name = "series", value.name = "pr2")
rib <- rbind(res[, .(W, series = "Rookie target share", lo = ts_lo, hi = ts_hi)],
             res[, .(W, series = "Draft slot", lo = pk_lo, hi = pk_hi)])
long[, series := factor(series, levels = c("Rookie target share", "Draft slot"))]
rib[,  series := factor(series, levels = c("Rookie target share", "Draft slot"))]

ymax <- max(rib$hi) * 1.04
p <- ggplot(long, aes(W, pr2, color = series)) +
  geom_ribbon(data = rib, aes(W, ymin = lo, ymax = hi, fill = series),
              alpha = 0.12, color = NA, inherit.aes = FALSE) +
  geom_vline(xintercept = cross_wk, linetype = "dashed", color = col_baseline,
             linewidth = 0.5) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.1) +
  annotate("text", x = cross_wk + 0.15, y = ymax * 0.97, hjust = 0, vjust = 1,
           size = 3.5, color = ink_primary, fontface = "bold",
           label = "Week 4: usage overtakes pedigree") +
  annotate("text", x = cross_wk + 0.15, y = ymax * 0.90, hjust = 0, vjust = 1,
           size = 3.1, color = ink_secondary, lineheight = 1.1,
           label = "By Halloween (week 8), draft slot uniquely explains ~1%\nof future production; cumulative target share explains ~14%") +
  annotate("text", x = 12, y = 0.080, hjust = 1, vjust = 0.5, size = 3.1,
           color = ink_secondary, lineheight = 1.1,
           label = "Only earned usage counts: share gained while the team's\nWR1 sat injured predicts nothing (std beta = -0.13, p = 0.46);\nshare earned with the WR1 active carries the whole signal\n(std beta = 0.59, p = 0.005)") +
  scale_color_manual(values = c(col_ts, col_pk), name = NULL) +
  scale_fill_manual(values = c(col_ts, col_pk), guide = "none") +
  scale_x_continuous(breaks = 1:12, minor_breaks = NULL) +
  scale_y_continuous(labels = label_percent(accuracy = 1), limits = c(0, ymax),
                     expand = expansion(mult = c(0, 0.02))) +
  labs(
    title    = "Draft pedigree goes stale by Week 4 of a WR's rookie season",
    subtitle = "Partial R-squared for years-2/3 receiving yards per season, re-estimated week by week: cumulative share of team\ntargets through rookie week W vs. draft slot (log overall pick), each controlling for the other",
    x = "Rookie season week (cumulative evidence through week W)",
    y = "Share of years-2-3 variance uniquely explained",
    caption = paste0("nflverse weekly stats & draft picks | WRs drafted 2011-2022, >=4 REG games in rookie wks 1-8 (n = 162)\n",
                     "Outcome: REG receiving yds/season in years 2-3, zero if out of the league | shaded: 80% bootstrap interval (500 resamples)\n",
                     "WR1 = teammate WR leading team in targets (min 20) | crossover holds in both eras (2011-16 / 2017-22) and for PPR PPG")
  ) +
  theme_nfl() +
  theme(legend.position = c(0.125, 0.86),
        legend.background = element_rect(fill = alpha(col_surface, 0.8), color = NA))

save_chart(p, "pedigree-half-life")
