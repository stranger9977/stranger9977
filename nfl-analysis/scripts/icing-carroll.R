# What's going on with Pete Carroll? He's the one coach outside the icing
# noise cone. Is his selective icing a real edge, or the fluke you expect from
# screening 21 coaches on tiny samples?
suppressMessages({library(data.table); library(splines); library(ggplot2); library(scales)})
setDTthreads(4)
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")
ROOT <- "/Users/nick/stranger9977/nfl-analysis"
SP <- file.path(ROOT, "scratch"); dir.create(SP, showWarnings=FALSE)
cache <- file.path(SP, "all_fg.rds")

if (!file.exists(cache)) {
  cols <- c("game_id","play_id","season","qtr","half_seconds_remaining","posteam","defteam",
            "timeout","timeout_team","play_type","desc","field_goal_attempt","field_goal_result",
            "kick_distance","kicker_player_name","kicker_player_id","score_differential",
            "roof","temp","wind","defteam_timeouts_remaining")
  res <- list()
  for (yr in 2000:2025) {
    d <- fread(sprintf("%s/data/play_by_play_%d.csv.gz", ROOT, yr), select=cols, showProgress=FALSE)
    setorder(d, game_id, play_id)
    d[, rid := seq_len(.N)][, gstart := rid[1L], by=game_id]
    d[, to_row := as.integer(!is.na(timeout) & timeout==1 & grepl("^\\s*Timeout", desc))]
    fg_idx <- d[field_goal_attempt==1 & !is.na(kick_distance) &
                field_goal_result %in% c("made","missed","blocked"), rid]
    iced <- ndef <- integer(length(fg_idx))
    for (k in seq_along(fg_idx)) {
      i <- fg_idx[k]; j <- i-1L; nd <- 0L
      while (j >= d$gstart[i] && d$to_row[j]==1L) {
        if (!is.na(d$timeout_team[j]) && d$timeout_team[j]==d$defteam[i]) nd <- nd+1L
        j <- j-1L }
      ndef[k] <- nd; iced[k] <- as.integer(nd>0L) }
    fg <- d[rid %in% fg_idx]; fg[, `:=`(iced=iced, n_def_ice_timeouts=ndef)]
    res[[as.character(yr)]] <- fg; rm(d); gc(verbose=FALSE)
  }
  saveRDS(rbindlist(res), cache)
}
fg <- readRDS(cache); fg[, made := as.integer(field_goal_result=="made")]
base <- glm(made ~ ns(kick_distance,5), data=fg, family=binomial)
fg[, exp_p := predict(base, fg, type="response")]; fg[, resid := made-exp_p]
fg[, `:=`(k_sum=sum(resid), k_n=.N), by=kicker_player_id]
fg[, kq := (k_sum-resid)/(k_n-1+60)]; fg[is.na(kicker_player_id)|kicker_player_id=="", kq:=0]
fg[, pressure := as.integer((half_seconds_remaining<=120 | qtr>=5) & score_differential>=-3 & score_differential<=0)]
fg[, situ := fifelse(qtr>=5,"OT",fifelse(qtr<=2,"end_H1","end_game"))]
fg[, takes_lead := as.integer(score_differential > -3)]
fg[, era := cut(season, c(1999,2005,2012,2019,2025), labels=c("2000-05","2006-12","2013-19","2020-25"))]
fg[, indoor := as.integer(roof %in% c("dome","closed"))]
fg[indoor==1, `:=`(temp2=68, wind2=0)][indoor==0, `:=`(temp2=temp, wind2=wind)]
fg[, wx_miss := as.integer(is.na(temp2)|is.na(wind2))]
fg[is.na(temp2), temp2 := median(fg$temp2,na.rm=TRUE)][is.na(wind2), wind2 := median(fg$wind2,na.rm=TRUE)]
pr <- fg[pressure==1]; pr[, opp := as.integer(iced==1 | defteam_timeouts_remaining>=1)]

g <- fread(file.path(ROOT,"data/games.csv"), select=c("game_id","home_team","away_team","home_coach","away_coach"))
pr <- merge(pr, g, by="game_id", all.x=TRUE)
pr[, def_coach := fifelse(defteam==home_team, home_coach, away_coach)]
m2 <- glm(made ~ iced + ns(kick_distance,4) + kq + indoor + wind2 + temp2 + wx_miss + era + situ +
          takes_lead + I(half_seconds_remaining<=40), data=pr[opp==1], family=binomial)
pr[, exp_noice := predict(m2, copy(pr)[, iced:=0L], type="response")]

## ---- coach effects (funnel table) ----
ce <- pr[iced==1 & opp==1, .(n=.N, made=sum(made), obs=mean(made), exp=mean(exp_noice),
         eff=mean(made)-mean(exp_noice)), by=def_coach][n>=8]
ice_rate <- pr[opp==1, .(opps=.N, rate=mean(iced)), by=def_coach]
ce <- merge(ce, ice_rate, by="def_coach"); setorder(ce, eff)
cat("=== per-coach icing effect (min 8 iced) ===\n"); print(ce)
pbar <- pr[iced==1 & opp==1, mean(exp_noice)]
ce[, z := eff/sqrt(pbar*(1-pbar)/n)]

## ---- Pete Carroll's actual iced kicks ----
cat("\n=== Pete Carroll's iced pressure kicks ===\n")
pc <- pr[iced==1 & opp==1 & def_coach=="Pete Carroll",
         .(season, kicker=kicker_player_name, dist=kick_distance,
           result=field_goal_result, exp_make=round(exp_noice,2))][order(season)]
print(pc)
cat(sprintf("\nCarroll: iced %d, made %d (%.0f%%), expected ~%.0f%%; effect %+.0f pts; ices %.0f%% of chances (league ~%.0f%%)\n",
    nrow(pc), sum(pc$result=="made"), 100*mean(pc$result=="made"), 100*mean(pc$exp_make),
    100*ce[def_coach=="Pete Carroll", eff], 100*ce[def_coach=="Pete Carroll", rate],
    100*pr[opp==1, mean(iced)]))

## ---- selectivity vs effect across coaches ----
cat(sprintf("\ncor(icing rate, effect) across %d coaches: r=%+.2f  (selective icing does NOT predict success)\n",
    nrow(ce), cor(ce$rate, ce$eff)))

## ---- THE SIMULATION: if icing did nothing, how often is one coach this clutch? ----
set.seed(1)
kicks <- pr[iced==1 & opp==1 & def_coach %in% ce$def_coach, .(def_coach, exp_noice)]
coaches <- ce$def_coach; nsim <- 20000
carroll_eff <- ce[def_coach=="Pete Carroll", eff]
min_eff <- numeric(nsim); any_beats <- logical(nsim)
kl <- split(kicks$exp_noice, kicks$def_coach)
for (s in 1:nsim) {
  effs <- vapply(kl, function(p) mean(rbinom(length(p),1,p)-p), numeric(1))
  min_eff[s] <- min(effs); any_beats[s] <- min(effs) <= carroll_eff
}
cat(sprintf("\nUnder the null (icing does nothing), P(at least one of %d coaches looks >= as clutch as Carroll) = %.2f\n",
    length(coaches), mean(any_beats)))
cat(sprintf("Carroll effect %+.0f pts sits at the %.0fth percentile of the flukiest-coach distribution.\n",
    100*carroll_eff, 100*mean(min_eff < carroll_eff)))

## ---- CHART: the one-in-twenty problem ----
sim <- data.table(min_eff=min_eff*100); ymax <- max(hist(sim$min_eff, breaks=seq(-70,2,2), plot=FALSE)$counts)
p <- ggplot(sim, aes(min_eff)) +
  geom_histogram(binwidth=2, fill=pal_cat[1], alpha=.28, color=NA, boundary=0) +
  geom_vline(xintercept=carroll_eff*100, color=pal_cat[2], linewidth=1.1) +
  annotate("label", x=carroll_eff*100, y=ymax*0.98, vjust=1,
           label=sprintf("Pete Carroll\n%+.0f pts on 8 kicks", 100*carroll_eff),
           color=pal_cat[2], fill=col_surface, label.size=NA, fontface="bold", size=3.5, lineheight=.95) +
  annotate("text", x=-64, y=ymax*0.82,
           label=paste0("If icing did nothing, this is how clutch the\nflukiest of 21 coaches still looks. Chance alone\n",
                        sprintf("beats Carroll's mark about %.0f%% of the time.", 100*mean(any_beats))),
           size=3.4, color=ink_secondary, family="mono", lineheight=1.1, hjust=0) +
  scale_x_continuous(labels=function(x) sprintf("%+.0f", x)) +
  labs(title="Pete Carroll didn't crack icing. Screening 21 coaches did.",
       subtitle="Simulated worlds where a defensive timeout changes nothing. Even so, the single luckiest of 21 coaches beats expectation\nabout this much roughly once a decade. Carroll's real result is that blip, on a sample of just eight kicks.",
       x="Most extreme coach's icing 'effect' under pure chance (points of make probability)", y="Simulated seasons",
       caption="nflverse play-by-play 2000-2025. 20,000 simulations; each of the 21 qualifying coaches (min 8 iced pressure kicks) gets his real kicks with the\nmodel's expected make probability, timeout or not. Carroll iced 8 pressure kicks (kickers made 3), and being selective doesn't help: icing rate vs effect r = +0.01.") +
  theme_nfl()
save_chart(p, "icing-carroll", width=10, height=6.0)
cat("\nDONE\n")
