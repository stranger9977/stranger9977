# Does establishing the run EARLY open up the pass LATER (later in H1, in H2,
# in Q4)? The game-level "pound it early, throw it late" claim.
# Confounder = game script: teams run early when winning, and winning changes
# late passing situations. So (a) restrict late passes to neutral WP, and
# (b) also demean within team-season (does a team pass better late in ITS OWN
# games where it ran more early?).
suppressMessages({library(data.table)}); setDTthreads(4)
ROOT <- "/Users/nick/stranger9977/nfl-analysis"
d <- as.data.table(readRDS(file.path(ROOT,"data/pbp_slim.rds")))
d <- d[season>=2015 & (qb_dropback==1|rush==1) & !is.na(epa) & !is.na(down) &
       (is.na(qb_kneel)|qb_kneel!=1) & (is.na(qb_spike)|qb_spike!=1) &
       !is.na(posteam)]
d[, is_pass := as.integer(qb_dropback==1)]
d[, is_run  := as.integer(rush==1 & qb_dropback==0)]

tg <- function(dd, id=c("game_id","posteam","season")) dd[, .SD, .SDcols=names(dd)]

# ---- early run investment (team-game), first half & Q1 ------------------
early <- d[qtr<=2, .(
  fh_run_att   = sum(is_run),
  fh_erd_run   = sum(is_run & down<=2),          # early-down first-half runs
  fh_run_epa   = mean(epa[is_run==1]),           # did the run WORK
  fh_run_succ  = mean(success[is_run==1], na.rm=TRUE)
), by=.(game_id,posteam,season)]
q1 <- d[qtr==1, .(q1_run_att=sum(is_run)), by=.(game_id,posteam)]

# ---- late passing, neutral game script (WP 20-80%) ----------------------
latepass <- function(dd) dd[is_pass==1 & vegas_wp>=0.2 & vegas_wp<=0.8,
                            .(epa=mean(epa), n=.N), by=.(game_id,posteam)]
h2 <- latepass(d[qtr%in%c(3,4)]); setnames(h2,c("epa","n"),c("h2_pass_epa","h2_n"))
q4 <- latepass(d[qtr==4]);        setnames(q4,c("epa","n"),c("q4_pass_epa","q4_n"))
q2 <- latepass(d[qtr==2]);        setnames(q2,c("epa","n"),c("q2_pass_epa","q2_n"))

M <- Reduce(function(a,b) merge(a,b,by=c("game_id","posteam"),all.x=TRUE),
            list(early,q1,h2,q4,q2))

cat("team-games:",nrow(M),"\n\n")
corr <- function(x,y,nm,minn){
  ok <- is.finite(x)&is.finite(y)&minn
  cat(sprintf("%-46s r=%+.3f  (n=%d)\n",nm,cor(x[ok],y[ok]),sum(ok)))
}
cat("=== RAW correlations (team-game) ===\n")
corr(M$fh_run_att,  M$h2_pass_epa, "first-half RUN ATTEMPTS -> H2 pass EPA", M$h2_n>=8)
corr(M$fh_run_att,  M$q4_pass_epa, "first-half RUN ATTEMPTS -> Q4 pass EPA", M$q4_n>=5)
corr(M$q1_run_att,  M$q2_pass_epa, "Q1 RUN ATTEMPTS -> Q2 pass EPA (later in H1)", M$q2_n>=5)
corr(M$fh_run_epa,  M$h2_pass_epa, "first-half RUN EPA (ran well) -> H2 pass EPA", M$h2_n>=8)
corr(M$fh_run_succ, M$h2_pass_epa, "first-half RUN SUCCESS RATE -> H2 pass EPA", M$h2_n>=8)

# ---- within team-season (demean: kill team-quality + game-script trait) --
demean <- function(dt, xcol, ycol, nfilt){
  z <- dt[is.finite(get(xcol)) & is.finite(get(ycol)) & nfilt]
  z[, `:=`(xd=get(xcol)-mean(get(xcol)), yd=get(ycol)-mean(get(ycol))),
    by=.(posteam,season)]
  cat(sprintf("%-46s r=%+.3f  (n=%d, %d team-seasons)\n",
      paste0("within-team  ",xcol,"->",ycol),
      cor(z$xd,z$yd), nrow(z), uniqueN(paste(z$posteam,z$season))))
}
cat("\n=== WITHIN team-season (same team, its own high vs low early-run games) ===\n")
demean(M,"fh_run_att","h2_pass_epa", M$h2_n>=8)
demean(M,"fh_run_att","q4_pass_epa", M$q4_n>=5)
demean(M,"fh_run_epa","h2_pass_epa", M$h2_n>=8)

# ---- bucket view for the chart: H2 neutral pass EPA by fh run attempts ---
Mb <- M[is.finite(fh_run_att)&is.finite(h2_pass_epa)&h2_n>=8]
Mb[, q := cut(fh_run_att, quantile(fh_run_att, 0:5/5, na.rm=TRUE),
              include.lowest=TRUE, labels=c("Fewest","","Middle","","Most"))]
cat("\n=== H2 neutral-script pass EPA by first-half run-attempt quintile ===\n")
print(Mb[, .(fh_runs=round(mean(fh_run_att),1), h2_pass_epa=round(mean(h2_pass_epa),3),
             n=.N), by=q][order(q)])

# ---- play-action steelman (FTN 2022-2024) -------------------------------
ftn <- rbindlist(lapply(2022:2024, function(y)
  fread(sprintf("%s/data/ftn_charting_%d.csv.gz",ROOT,y),
        select=c("nflverse_game_id","nflverse_play_id","is_play_action"))))
setnames(ftn,c("game_id","play_id","pa"))
dp <- merge(d[season>=2022 & is_pass==1, .(game_id,play_id,posteam,qtr,epa,vegas_wp)],
            ftn, by=c("game_id","play_id"))
pa2 <- dp[qtr%in%c(3,4) & vegas_wp>=0.2 & vegas_wp<=0.8,
          .(pa_epa=mean(epa[pa==TRUE],na.rm=TRUE),
            npa=mean(epa[pa!=TRUE],na.rm=TRUE),
            n_pa=sum(pa==TRUE,na.rm=TRUE)), by=.(game_id,posteam)]
pa2[, pa_prem := pa_epa - npa]
PA <- merge(early, pa2, by=c("game_id","posteam"))
PA <- PA[is.finite(fh_run_att)&is.finite(pa_prem)&n_pa>=4]
cat("\n=== Does early run establish the LATE play-action premium? (2022-24) ===\n")
cat(sprintf("first-half run attempts -> H2 play-action premium: r=%+.3f (n=%d)\n",
    cor(PA$fh_run_att,PA$pa_prem), nrow(PA)))
cat(sprintf("first-half run EPA      -> H2 play-action premium: r=%+.3f (n=%d)\n",
    cor(PA$fh_run_epa[is.finite(PA$fh_run_epa)],PA$pa_prem[is.finite(PA$fh_run_epa)]),
    sum(is.finite(PA$fh_run_epa))))
PA[, q := cut(fh_run_att, quantile(fh_run_att,0:4/4,na.rm=TRUE), include.lowest=TRUE,
              labels=c("Fewest early runs","","","Most early runs"))]
print(PA[, .(fh_runs=round(mean(fh_run_att),1), pa_epa=round(mean(pa_epa),3),
             pa_premium=round(mean(pa_prem),3), n=.N), by=q][order(q)])
cat("\nDONE\n")
