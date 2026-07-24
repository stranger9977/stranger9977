# Wind-Savvy Coaches: testing the "wind-blind coaches" hypothesis on long field goals.
#
# Hypothesis tested: on 48-58 yd FGs outdoors, make rates crater 15-25 pts in wind
# >12-15 mph while coaches' 4th-down attempt rates stay flat (a pricing error).
# Result: the OPPOSITE. Coaches cut attempt rates sharply as wind rises
# (logit wind coef -0.043/mph, p<0.001, controlling distance/score/time), while
# make rates on the kicks actually taken stay statistically flat
# (wind coef -0.016/mph, p=0.16). Not explained by kicker selection: kickers who
# attempt in 11+ mph wind make 67.6% of calm-wind 48-58 yd kicks vs 66.9% overall.
# Pattern holds in both 2015-19 and 2020-24 halves.

library(data.table)
library(ggplot2)
library(scales)
source("/home/user/stranger9977/nfl-analysis/scripts/theme_nfl.R")

pbp <- setDT(readRDS("/home/user/stranger9977/nfl-analysis/data/pbp_slim.rds"))
d   <- pbp[roof == "outdoors" & !is.na(wind) & season_type == "REG"]

brks <- c(-1, 5, 10, 15, 99)
labs <- c("0-5", "6-10", "11-15", "16+")

# Decision sample: 4th downs where a 48-58 yd FG was on the table, game still live
dec <- d[down == 4 & !is.na(play_type) & !play_type %chin% c("", "no_play") &
         yardline_100 + 17 >= 48 & yardline_100 + 17 <= 58 &
         abs(score_differential) <= 8 & game_seconds_remaining > 300]
dec[, bucket := cut(wind, brks, labels = labs)]

# Physics sample: all 48-58 yd FG attempts (make rate conditional on kicking)
att <- d[field_goal_attempt == 1 & kick_distance >= 48 & kick_distance <= 58]
att[, `:=`(made = as.integer(field_goal_result == "made"),
           bucket = cut(wind, brks, labels = labs))]

wilson <- function(x, n, z = 1.96) {
  p <- x / n
  lo <- (p + z^2 / (2 * n) - z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) / (1 + z^2 / n)
  hi <- (p + z^2 / (2 * n) + z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) / (1 + z^2 / n)
  list(lo = lo, hi = hi)
}

sum_dec <- dec[, .(n = .N, x = sum(field_goal_attempt)), by = bucket][order(bucket)]
sum_att <- att[, .(n = .N, x = sum(made)),               by = bucket][order(bucket)]
sum_dec[, `:=`(series = "Coach attempts the kick", rate = x / n)]
sum_att[, `:=`(series = "Kick is good",            rate = x / n)]
plot_dt <- rbind(sum_dec, sum_att)
plot_dt[, c("lo", "hi") := wilson(x, n)]
plot_dt[, xnum := as.integer(bucket)]
stopifnot(plot_dt[, min(n)] >= 25)   # min-sample guard (smallest cell: 105 kicks)

# Regression checks quoted in annotations
dec[, imp_dist := yardline_100 + 17]
m_dec <- glm(field_goal_attempt ~ imp_dist + abs(score_differential) +
               game_seconds_remaining + wind, data = dec, family = binomial)
m_att <- glm(made ~ kick_distance + wind, data = att, family = binomial)
cat("decision wind coef:\n"); print(summary(m_dec)$coefficients["wind", ])
cat("make wind coef:\n");     print(summary(m_att)$coefficients["wind", ])

end_labs <- plot_dt[xnum %in% c(1, 4)]
n_labs   <- plot_dt[series == "Kick is good"]

p <- ggplot(plot_dt, aes(xnum, rate, color = series, fill = series)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.14, color = NA) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.6) +
  geom_text(data = end_labs,
            aes(label = percent(rate, accuracy = 1),
                vjust = ifelse(series == "Kick is good", -1.1, 1.9)),
            color = ink_primary, fontface = "bold", size = 3.6, show.legend = FALSE) +
  annotate("text", x = 3.02, y = 0.755, hjust = 0, size = 3.4, color = ink_secondary,
           label = "Make rate ~flat with wind\n(-1.6 pp per 5 mph, p = 0.16)") +
  annotate("text", x = 2.55, y = 0.30, hjust = 0, size = 3.4, color = ink_secondary,
           label = "Attempt rate falls 16 pts\nby 11-15 mph (p < 0.001)") +
  annotate("text", x = n_labs$xnum, y = 0.145, size = 3,   color = ink_muted,
           label = paste0(n_labs$n, " kicks")) +
  annotate("text", x = as.integer(sum_dec$bucket), y = 0.115, size = 3, color = ink_muted,
           label = paste0(sum_dec$n, " 4th downs")) +
  scale_x_continuous(breaks = 1:4, labels = paste(labs, "mph"),
                     expand = expansion(add = 0.25)) +
  scale_y_continuous(labels = percent_format(accuracy = 1),
                     limits = c(0.10, 0.82), breaks = seq(0.2, 0.8, 0.2)) +
  scale_color_manual(values = pal_cat[1:2],
                     breaks = c("Coach attempts the kick", "Kick is good")) +
  scale_fill_manual(values = pal_cat[1:2], guide = "none") +
  labs(
    title    = "Coaches aren't wind-blind: they shelve long field goals\nbefore the wind ever craters the kicks",
    subtitle = "Outdoor 4th downs with a 48-58 yd kick available (score within 8, >5 min left): how often coaches attempt it,\nvs. the make rate on all 48-58 yd attempts, by game wind speed",
    x = "Wind speed", y = "Rate", color = NULL,
    caption = paste0(
      "Data: nflverse play-by-play, 2015-2024 regular season, outdoor stadiums with recorded wind.\n",
      "1,456 qualifying 4th downs; 1,444 kicks; min 105 kicks per wind bucket (>=25 required). Bands: 95% Wilson CIs.\n",
      "Make-rate flatness holds controlling for exact kick distance; attempt-rate decline holds controlling for\n",
      "distance, score, and clock. Pattern holds in both 2015-19 and 2020-24.")
  ) +
  theme_nfl() +
  theme(legend.position = "top",
        legend.justification = "left",
        legend.margin = margin(t = 0, b = 2))

save_chart(p, "wind_savvy_coaches")
