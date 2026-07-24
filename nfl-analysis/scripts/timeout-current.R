# Timeout discipline, focused on THIS YEAR'S coaches. Same two sins as the
# career leaderboard (burning them early; leaving them on the table in
# one-score losses), but restricted to head coaches active in 2025, using
# their full careers for stability.
suppressMessages({library(data.table); library(ggplot2); library(scales); library(ggrepel)})
setDTthreads(4)
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")
ROOT <- "/Users/nick/stranger9977/nfl-analysis"
SP <- file.path(ROOT,"scratch"); dir.create(SP, showWarnings=FALSE)
cache <- file.path(SP, "timeout_tg.rds")

if (!file.exists(cache)) {
  locf <- function(x){ok<-!is.na(x); i<-cumsum(ok); y<-x[ok][pmax(i,1)]; y[i==0]<-NA_character_; y}
  cols <- c("game_id","play_id","qtr","half_seconds_remaining","game_seconds_remaining","timeout",
            "timeout_team","posteam","posteam_timeouts_remaining","defteam_timeouts_remaining",
            "score_differential","desc","home_team","away_team")
  out <- list()
  for (yr in 2000:2025) {
    d <- fread(sprintf("%s/data/play_by_play_%d.csv.gz",ROOT,yr), select=cols, showProgress=FALSE)
    setorder(d, game_id, play_id); d[posteam=="", posteam:=NA_character_]
    d[, pos_next := rev(locf(rev(posteam))), by=game_id]
    to <- d[timeout==1 & !is.na(timeout_team) & timeout_team!="",
            .(game_id, qtr, half_seconds_remaining, timeout_team, pos_next, injury=grepl("njury",desc))]
    tg <- to[, .(burns_off_early=sum(timeout_team==pos_next & half_seconds_remaining>240 & qtr<=4 & !injury, na.rm=TRUE)),
             by=.(game_id, team=timeout_team)]
    eg <- d[!is.na(posteam) & !is.na(posteam_timeouts_remaining) & !is.na(defteam_timeouts_remaining),
            .SD[.N, .(qtr_end=qtr, posteam, pos_to=posteam_timeouts_remaining, def_to=defteam_timeouts_remaining)], by=game_id]
    m2 <- d[qtr==4 & game_seconds_remaining>=120 & !is.na(posteam) & !is.na(score_differential),
            .SD[.N, .(pos2=posteam, sd_2min=score_differential)], by=game_id]
    teams <- d[, .(home=home_team[1], away=away_team[1]), by=game_id]
    x <- rbind(teams[,.(game_id,team=home)], teams[,.(game_id,team=away)])
    x <- merge(x, tg, by=c("game_id","team"), all.x=TRUE); x[is.na(burns_off_early), burns_off_early:=0L]
    x <- merge(x, eg, by="game_id", all.x=TRUE); x[, to_end := fifelse(team==posteam, pos_to, def_to)]
    x <- merge(x[,.(game_id,team,burns_off_early,qtr_end,to_end)], m2, by="game_id", all.x=TRUE)
    x[, margin_2min := fifelse(team==pos2, sd_2min, -sd_2min)][, c("pos2","sd_2min"):=NULL]
    x[, season := yr]; out[[as.character(yr)]] <- x
    rm(d,to,eg,m2,teams,x); gc(verbose=FALSE)
  }
  saveRDS(rbindlist(out), cache)
}
tg <- readRDS(cache)
g <- fread(file.path(ROOT,"data/games.csv"),
           select=c("game_id","season","home_team","away_team","home_score","away_score","home_coach","away_coach"))
g <- g[season>=2000 & season<=2025 & !is.na(home_score)]
fixt <- function(x) fcase(x=="STL","LA", x=="SD","LAC", x=="OAK","LV", rep(TRUE,length(x)),x)
g[, `:=`(home_team=fixt(home_team), away_team=fixt(away_team))]
gl <- rbind(g[,.(game_id,team=home_team,pts=home_score,opp=away_score,coach=home_coach,season)],
            g[,.(game_id,team=away_team,pts=away_score,opp=home_score,coach=away_coach,season)])
tg <- merge(tg, gl[,.(game_id,team,pts,opp,coach)], by=c("game_id","team"))
tg[, margin := pts-opp]
tg[, close_trail_loss := !is.na(margin_2min) & margin_2min<=-1 & margin_2min>=-8 & margin<0 & qtr_end<=4]
tg[, died := as.integer(close_trail_loss & !is.na(to_end) & to_end>=1)]
tg[, exp_burn := mean(burns_off_early), by=season]

# active in 2025
active <- unique(gl[season==2025]$coach)
co <- tg[, .(n_games=.N, last=max(season), first=min(season),
             burn_vs=mean(burns_off_early-exp_burn), burn_pg=mean(burns_off_early),
             n_ctl=sum(close_trail_loss), died_n=sum(died)), by=coach]
co[, died_rate := died_n/pmax(n_ctl,1)]
co <- co[coach %in% active]
lg_died <- tg[close_trail_loss==TRUE, mean(died)]
cat("league left-on-table rate:", round(lg_died,3), "| active-2025 coaches:", nrow(co), "\n\n")
cat("=== current coaches: timeout discipline (career) ===\n")
print(co[order(burn_vs)][, .(coach, n_games, since=first, burn_vs=round(burn_vs,2),
        left_pct=round(100*died_rate), left=paste0(died_n,"/",n_ctl))])

# map: burn (x) vs left-on-table (y); need close-loss sample for y
mp <- co[n_games>=40 & n_ctl>=10]
cat("\nmapped (>=40 games & >=10 close losses):", nrow(mp), "coaches\n")
lg_x <- 0
p <- ggplot(mp, aes(burn_vs, died_rate)) +
  annotate("rect", xmin=-Inf, xmax=lg_x, ymin=-Inf, ymax=lg_died, fill=pal_cat[3], alpha=.06) +
  annotate("rect", xmin=lg_x, xmax=Inf, ymin=lg_died, ymax=Inf, fill=pal_cat[2], alpha=.06) +
  geom_hline(yintercept=lg_died, color=col_baseline, linewidth=.4) +
  geom_vline(xintercept=lg_x, color=col_baseline, linewidth=.4) +
  annotate("text", x=min(mp$burn_vs), y=-0.01, label="DISCIPLINED", hjust=0, vjust=1,
           size=3, fontface="bold", color=pal_cat[3], family="sans") +
  annotate("text", x=max(mp$burn_vs), y=max(mp$died_rate)+.01, label="LOOSE WITH BOTH", hjust=1, vjust=0,
           size=3, fontface="bold", color=pal_cat[2], family="sans") +
  annotate("text", x=lg_x, y=max(mp$died_rate)+.02, label="league average", hjust=-.05, vjust=1,
           size=2.7, color=ink_muted, family="mono") +
  geom_point(aes(size=n_games), color=pal_cat[1], alpha=.85) +
  geom_text_repel(aes(label=coach), size=3.1, color=ink_primary, fontface="bold",
                  seed=3, max.overlaps=30, box.padding=.45, min.segment.length=0, segment.color=col_baseline) +
  scale_size_area(max_size=7, guide="none") +
  scale_x_continuous(labels=number_format(.1,style_positive="plus")) +
  scale_y_continuous(labels=percent_format(1), limits=c(-0.02, max(mp$died_rate)+.03)) +
  labs(title="Where this year's coaches stand on the clock",
       subtitle="Every head coach active in 2025, on the two ways to waste a timeout (career figures). Right = burns more early;\nup = more often walks off a one-score loss with a timeout unused. Bottom-left is disciplined; top-right is loose with both.",
       x="Burned early: offensive timeouts before the last 4:00, per game vs league",
       y="Left on the table: share of one-score losses ending with a timeout unused",
       caption="nflverse play-by-play + games, 2000-2025, active-2025 head coaches with 40+ career games and 10+ one-score losses. Point size = career games.\nLeague leaves a timeout unused in 15% of one-score losses. Newer coaches (fewer close losses) are listed in the notes, not plotted.") +
  theme_nfl() + theme(legend.position="none")
save_chart(p, "timeout-current", width=10, height=7.0)

# newer current coaches (too few close losses to plot y, but burn is reliable)
newer <- co[n_ctl<10 | n_games<40][order(burn_vs)]
cat("\nnewer current coaches (burn rate only):\n")
print(newer[, .(coach, n_games, burn_vs=round(burn_vs,2), left=paste0(died_n,"/",n_ctl))])
cat("\nDONE\n")
