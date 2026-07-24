# Steelman the run-first coach and test every angle of "establish the run /
# wear them down / December football", plus the reverse: does the PASS set up
# the run (light boxes)?
suppressMessages({library(data.table)}); setDTthreads(4)
ROOT <- "/Users/nick/stranger9977/nfl-analysis"
d <- as.data.table(readRDS(file.path(ROOT,"data/pbp_slim.rds")))
d <- d[season>=2015 & (qb_dropback==1|rush==1) & !is.na(epa) & !is.na(down) &
       (is.na(qb_kneel)|qb_kneel!=1) & (is.na(qb_spike)|qb_spike!=1) & !is.na(posteam)]
d[, is_pass := as.integer(qb_dropback==1)]
d[, is_run  := as.integer(rush==1 & qb_dropback==0)]

cat("############ ANGLE A: does the PASS set up the run? (light boxes) ########\n")
# join defenders in box (participation 2016-2023)
box <- rbindlist(lapply(2016:2023, function(y){
  f <- sprintf("%s/data/pbp_participation_%d.csv.gz",ROOT,y)
  z <- fread(f, select=c("nflverse_game_id","play_id","defenders_in_box"))
  setnames(z,"nflverse_game_id","game_id"); z
}))
r <- merge(d[is_run==1 & down<=2, .(game_id,play_id,posteam,season,epa,success,yards_gained,down,ydstogo)],
           box[!is.na(defenders_in_box) & defenders_in_box>0], by=c("game_id","play_id"))
r[, box_b := fifelse(defenders_in_box<=6,"light (6-)",
              fifelse(defenders_in_box==7,"7","stacked (8+)"))]
cat("\nEarly-down RUN value by box count (2016-2023):\n")
print(r[, .(epa=round(mean(epa),3), succ=round(mean(success),3),
            ypc=round(mean(yards_gained),2), n=.N), by=box_b][order(box_b)])

# who faces light boxes? teams that can pass. team-season: pass rate & pass
# EPA vs avg box faced on early runs
teamrun <- r[, .(box=mean(defenders_in_box), nrun=.N), by=.(posteam,season)]
teampass <- d[is_pass==1 & down<=2, .(pass_epa=mean(epa), passrate=NA_real_), by=.(posteam,season)]
edrate <- d[down<=2, .(passrate=mean(is_pass)), by=.(posteam,season)]
T <- Reduce(function(a,b) merge(a,b,by=c("posteam","season")),
            list(teamrun[nrun>=100], teampass[,.(posteam,season,pass_epa)], edrate))
cat(sprintf("\nteam-seasons=%d\n",nrow(T)))
cat(sprintf("early-down PASS RATE      vs avg box faced on runs: r=%+.3f\n", cor(T$passrate,T$box)))
cat(sprintf("early-down PASS EPA (good) vs avg box faced on runs: r=%+.3f\n", cor(T$pass_epa,T$box)))
cat("  (negative = better/heavier passing earns LIGHTER boxes)\n")

cat("\n\n############ ANGLE B: do defenses WEAR DOWN? (attrition) ##############\n")
# rush efficiency by quarter
cat("\nRUN efficiency by quarter (all situations):\n")
print(d[is_run==1 & qtr<=4, .(epa=round(mean(epa),3), succ=round(mean(success),3),
        ypc=round(mean(yards_gained),2), n=.N), by=qtr][order(qtr)])
# neutral WP only (strip game script: trailing teams pass, leading teams run late)
cat("\nRUN efficiency by quarter, NEUTRAL win prob 20-80% only:\n")
print(d[is_run==1 & qtr<=4 & vegas_wp>=0.2 & vegas_wp<=0.8,
        .(epa=round(mean(epa),3), succ=round(mean(success),3),
          ypc=round(mean(yards_gained),2), n=.N), by=qtr][order(qtr)])
# cumulative carries in game -> that offense's LATER run efficiency (Q4 neutral)
setorder(d, game_id, posteam, play_id)
d[, cum_rush := cumsum(shift(is_run, fill=0)), by=.(game_id,posteam)]
early_carries <- d[qtr<=2, .(h1_carries=sum(is_run)), by=.(game_id,posteam)]
q4run <- d[qtr==4 & is_run==1 & vegas_wp>=0.2 & vegas_wp<=0.8,
           .(q4_run_epa=mean(epa), q4_run_succ=mean(success), n=.N), by=.(game_id,posteam)]
WD <- merge(early_carries, q4run[n>=3], by=c("game_id","posteam"))
cat(sprintf("\nfirst-half CARRIES vs Q4 run EPA (neutral): r=%+.3f (n=%d team-games)\n",
    cor(WD$h1_carries,WD$q4_run_epa), nrow(WD)))
WD[, cb := cut(h1_carries, c(-1,8,12,16,100), labels=c("<=8","9-12","13-16","17+"))]
cat("Q4 run efficiency by how much they ran in H1:\n")
print(WD[, .(q4_run_epa=round(mean(q4_run_epa),3), q4_succ=round(mean(q4_run_succ),3),
             n=.N), by=cb][order(cb)])

cat("\n\n############ ANGLE C: DECEMBER FOOTBALL / cold + wind ##################\n")
w <- d[roof=="outdoors" & !is.na(temp)]
w[, temp_b := cut(temp, c(-20,25,35,45,55,70,120),
                  labels=c("<=25","26-35","36-45","46-55","56-70","70+"))]
adv <- function(dd) dd[, .(pass_epa=mean(epa[is_pass==1]), run_epa=mean(epa[is_run==1]),
                           pass_gap=mean(epa[is_pass==1])-mean(epa[is_run==1]),
                           passrate=mean(is_pass), n=.N), by=temp_b][order(temp_b)]
cat("\nPass vs run EPA by TEMPERATURE (outdoor games):\n")
print(adv(w)[, lapply(.SD, function(x) if(is.numeric(x)) round(x,3) else x)])
cat("\n(dome baseline)\n")
print(d[roof %in% c("dome","closed"), .(pass_epa=round(mean(epa[is_pass==1]),3),
        run_epa=round(mean(epa[is_run==1]),3),
        gap=round(mean(epa[is_pass==1])-mean(epa[is_run==1]),3), n=.N)])
# wind
w[, wind_b := cut(fifelse(is.na(wind),0,wind), c(-1,5,10,15,60),
                  labels=c("0-5","6-10","11-15","16+"))]
cat("\nPass vs run EPA by WIND (outdoor):\n")
print(w[, .(pass_gap=round(mean(epa[is_pass==1])-mean(epa[is_run==1]),3),
            passrate=round(mean(is_pass),3), n=.N), by=wind_b][order(wind_b)])
# late season / playoffs
cat("\nPass-minus-run EPA gap by month bucket:\n")
d[, mo := fifelse(week<=8,"Sep-Oct (wk1-8)", fifelse(week<=14,"Nov-early Dec (9-14)","late Dec-Jan (15+)"))]
print(d[roof=="outdoors", .(pass_gap=round(mean(epa[is_pass==1])-mean(epa[is_run==1]),3),
        passrate=round(mean(is_pass),3), n=.N), by=mo])
cat("\nDONE\n")
