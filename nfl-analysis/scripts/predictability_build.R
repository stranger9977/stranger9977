# =====================================================================
# Play-caller PREDICTABILITY analysis, 2015-2025
# Do the best play callers become UNPREDICTABLE, or does being good
# let them be predictable?
# Builds per caller-season + career tables -> scratchpad RDS for charts.
# =====================================================================
suppressMessages(library(data.table))
setDTthreads(2)

DATA <- "/home/user/stranger9977/nfl-analysis/data"
OUT  <- "/tmp/claude-0/-home-user-stranger9977/f03221fa-fab0-55bd-bf7a-5b49b7ec5a63/scratchpad"

# ---- 1. Load & filter called plays -----------------------------------
keep <- c("game_id","season","week","posteam","home_team","away_team",
          "down","ydstogo","yardline_100","qtr","half_seconds_remaining",
          "score_differential","qb_dropback","rush","qb_scramble",
          "qb_kneel","qb_spike","vegas_wp","xpass","pass_oe","epa",
          "play_id","drive")
d <- as.data.table(readRDS(file.path(DATA,"pbp_slim.rds")))
d <- d[season>=2015 & season<=2025, ..keep]

d[, called := ((qb_dropback==1 | rush==1) &
               (is.na(qb_kneel)|qb_kneel!=1) &
               (is.na(qb_spike)|qb_spike!=1))]
d <- d[called==TRUE & down %in% 1:4 &
       vegas_wp>=0.05 & vegas_wp<=0.95 &
       !is.na(pass_oe) & !is.na(yardline_100) & !is.na(score_differential)]
d[, is_pass := as.integer(qb_dropback==1)]

# ---- 2. Situation cells ----------------------------------------------
d[, togo_b := cut(ydstogo, c(0,3,6,10,100),
                  labels=c("1-3","4-6","7-10","11+"))]
d[, zone_b := cut(yardline_100, c(0,20,50,80,100),
                  labels=c("rz1-20","21-50","51-80","81-100"))]
d[, score_b := cut(score_differential, c(-Inf,-8.5,8.5,Inf),
                   labels=c("trail","close","lead"))]
d[, half := ifelse(qtr<=2,"H1", ifelse(qtr==5,"OT","H2"))]
d[, cell := paste(down, togo_b, zone_b, score_b, half, sep="|")]
gc()

# ---- 3. League-wide empirical cell pass rate (the expectation) -------
lg <- d[, .(lg_p = mean(is_pass), lg_n = .N), by=cell]
d  <- merge(d, lg, by="cell", all.x=TRUE)
lg_overall <- mean(d$is_pass)

# ---- 4. Play-caller attribution --------------------------------------
pc <- fread(file.path(DATA,"playcallers.csv"),
            select=c("season","week","team","game_id","off_play_caller"))
pc <- pc[season<=2025 & !is.na(off_play_caller) & off_play_caller!=""]
# normalize obvious spelling whitespace
pc[, off_play_caller := trimws(off_play_caller)]
d <- merge(d, pc, by.x=c("game_id","season","week","posteam"),
                  by.y=c("game_id","season","week","team"), all.x=TRUE)
cat("plays w/o caller match:", sum(is.na(d$off_play_caller)),
    "of", nrow(d), "\n")
# fallback for unmatched: head coach from games.csv
gm <- fread(file.path(DATA,"games.csv"),
            select=c("game_id","home_team","away_team","home_coach","away_coach"))
d <- merge(d, gm[,.(game_id,home_team,home_coach,away_coach)], by="game_id",
           all.x=TRUE)
d[is.na(off_play_caller),
  off_play_caller := ifelse(posteam==home_team, home_coach, away_coach)]
d <- d[!is.na(off_play_caller)]
cat("final plays:", nrow(d), " unique callers:",
    uniqueN(d$off_play_caller), "\n")
gc()

# ---- 5. Previous-play call within drive (1st-order Markov) -----------
setorder(d, game_id, posteam, drive, play_id)
d[, prev_pass := shift(is_pass), by=.(game_id, posteam, drive)]
# prev_pass NA = first play of drive (no info) -> its own group

# ---- 6. Entropy helpers ----------------------------------------------
Hbin <- function(p){
  p <- pmin(pmax(p,1e-9),1-1e-9)
  -(p*log2(p) + (1-p)*log2(1-p))
}
K <- 15  # empirical-Bayes shrinkage strength toward league cell rate

# ---- 7. Per caller-season metrics ------------------------------------
d[, cs := paste(off_play_caller, season, sep="__")]

# (b) situational unpredictability: shrunk within-cell pass rate entropy
cs_cell <- d[, .(n_cell=.N, p_raw=mean(is_pass), lg_p=lg_p[1]),
             by=.(cs, off_play_caller, season, cell)]
cs_cell[, p_shr := (n_cell*p_raw + K*lg_p)/(n_cell + K)]
cs_cell[, H_cell := Hbin(p_shr)]
cs_cell[, Hlg_cell := Hbin(lg_p)]
# guessability: prob an optimal situational guesser calls the play right
cs_cell[, g_cell := pmax(p_shr, 1-p_shr)]
cs_cell[, glg_cell := pmax(lg_p, 1-lg_p)]

# (c) sequence model: shrink within (cell x prev) toward the caller's own
#     shrunk cell rate (so lift = pure gain from knowing prev call)
d2 <- d[!is.na(prev_pass)]
cs_cellprev <- d2[, .(n_cp=.N, p_raw=mean(is_pass)),
                  by=.(cs, cell, prev_pass)]
# bring in caller's shrunk cell rate as the prior mean
cs_cellprev <- merge(cs_cellprev, cs_cell[,.(cs,cell,p_shr_cell=p_shr)],
                     by=c("cs","cell"), all.x=TRUE)
cs_cellprev[, p_shr := (n_cp*p_raw + K*p_shr_cell)/(n_cp + K)]
cs_cellprev[, H_cp := Hbin(p_shr)]

# aggregate to caller-season, weighting cells by play counts
agg_situ <- cs_cell[, .(
  n_plays  = sum(n_cell),
  H_situ   = sum(H_cell*n_cell)/sum(n_cell),     # unpredictability (bits)
  H_lg     = sum(Hlg_cell*n_cell)/sum(n_cell),   # league in same cells
  guess    = sum(g_cell*n_cell)/sum(n_cell),     # caller guessability
  guess_lg = sum(glg_cell*n_cell)/sum(n_cell)    # league guessability, same cells
), by=.(cs, off_play_caller, season)]
agg_situ[, H_vs_lg := H_situ - H_lg]             # <0 = more predictable than lg
agg_situ[, guess_xs := (guess - guess_lg)*100]   # extra pp guessed vs league

# sequence: entropy given cell+prev, weighted; and matched situ entropy on d2
# recompute situ entropy on the SAME plays that have a prev, for a fair lift
cs_cell_m <- d2[, .(n_cell=.N, p_raw=mean(is_pass), lg_p=lg_p[1]),
                by=.(cs, cell)]
cs_cell_m[, p_shr := (n_cell*p_raw + K*lg_p)/(n_cell+K)]
cs_cell_m[, H_cell := Hbin(p_shr)]
agg_situ_m <- cs_cell_m[, .(H_situ_m = sum(H_cell*n_cell)/sum(n_cell),
                            n_m=sum(n_cell)), by=cs]
agg_seq <- cs_cellprev[, .(H_seq = sum(H_cp*n_cp)/sum(n_cp)), by=cs]
agg_seq <- merge(agg_seq, agg_situ_m, by="cs")
agg_seq[, seq_lift := H_situ_m - H_seq]          # bits gained from prev call

# (a) situational lean = |net pass over expected| (pass_oe is 0-100 pts)
agg_lean <- d[, .(lean = abs(mean(pass_oe))/100,      # net directional lean
                  lean_abs = mean(abs(pass_oe))/100), by=cs]

# offense EPA/play (all called plays)
agg_epa <- d[, .(epa_play = mean(epa)), by=cs]

# ---- 8. Combine ------------------------------------------------------
tab <- Reduce(function(a,b) merge(a,b,by="cs",all.x=TRUE),
              list(agg_situ[,.(cs,off_play_caller,season,n_plays,H_situ,H_lg,
                               H_vs_lg,guess,guess_lg,guess_xs)],
                   agg_seq[,.(cs,H_seq,seq_lift)],
                   agg_lean, agg_epa))
tab <- tab[n_plays>=300]
cat("caller-seasons >=300 plays:", nrow(tab), "\n")

# next-season EPA (dodge same-season contamination)
nxt <- agg_epa2 <- d[, .(epa_play=mean(epa)), by=.(off_play_caller,season)]
setnames(nxt, "epa_play","epa_next")
nxt[, season := season-1]
tab <- merge(tab, nxt, by=c("off_play_caller","season"), all.x=TRUE)

saveRDS(tab, file.path(OUT,"pred_tab.rds"))
saveRDS(lg,  file.path(OUT,"pred_league_cells.rds"))

# ---- 9. Career aggregation (weight by plays) -------------------------
career <- tab[, .(
  seasons  = uniqueN(season),
  n_plays  = sum(n_plays),
  H_situ   = sum(H_situ*n_plays)/sum(n_plays),
  H_vs_lg  = sum(H_vs_lg*n_plays)/sum(n_plays),
  guess_xs = sum(guess_xs*n_plays)/sum(n_plays),
  seq_lift = sum(seq_lift*n_plays)/sum(n_plays),
  lean     = sum(lean*n_plays)/sum(n_plays),
  epa_play = sum(epa_play*n_plays)/sum(n_plays),
  last_season = max(season)
), by=off_play_caller]
career <- career[n_plays>=1000]
saveRDS(career, file.path(OUT,"pred_career.rds"))
cat("careers >=1000 plays:", nrow(career), "\n")

# ---- 10. Correlations (the payoff question) --------------------------
cat("\n=== SAME-SEASON correlations (caller-season, n=",nrow(tab),") ===\n")
cat("H_situ  vs EPA/play:  r=", round(cor(tab$H_situ,tab$epa_play),3),"\n")
cat("H_vs_lg vs EPA/play:  r=", round(cor(tab$H_vs_lg,tab$epa_play),3),"\n")
cat("seq_lift vs EPA/play: r=", round(cor(tab$seq_lift,tab$epa_play),3),"\n")
cat("lean    vs EPA/play:  r=", round(cor(tab$lean,tab$epa_play),3),"\n")
tn <- tab[!is.na(epa_next)]
cat("\n=== NEXT-SEASON correlations (n=",nrow(tn),") ===\n")
cat("H_situ  vs EPA_next:  r=", round(cor(tn$H_situ,tn$epa_next),3),"\n")
cat("H_vs_lg vs EPA_next:  r=", round(cor(tn$H_vs_lg,tn$epa_next),3),"\n")
cat("seq_lift vs EPA_next: r=", round(cor(tn$seq_lift,tn$epa_next),3),"\n")

cat("\n=== CAREER leaderboard extremes (n>=1000) ===\n")
setorder(career, H_vs_lg)
cat("\nMOST PREDICTABLE (lowest H_vs_lg, below-league entropy):\n")
print(career[1:12,.(off_play_caller,n_plays,H_situ=round(H_situ,3),
       H_vs_lg=round(H_vs_lg,3),seq_lift=round(seq_lift,3),
       epa=round(epa_play,3),last_season)])
cat("\nMOST UNPREDICTABLE (highest H_vs_lg):\n")
print(career[(.N-11):.N,.(off_play_caller,n_plays,H_situ=round(H_situ,3),
       H_vs_lg=round(H_vs_lg,3),seq_lift=round(seq_lift,3),
       epa=round(epa_play,3),last_season)])

cat("\n=== Elite callers spotlight (career) ===\n")
elite <- c("Andy Reid","Kyle Shanahan","Sean McVay","Matt LaFleur",
           "Sean Payton","Kliff Kingsbury","Ben Johnson","Shane Steichen",
           "Mike McDaniel","Josh McDaniels","Doug Pederson","Brian Daboll",
           "Zac Taylor","Kevin O'Connell")
print(career[off_play_caller %in% elite][order(-epa_play),
   .(off_play_caller,n_plays,H_situ=round(H_situ,3),
     H_vs_lg=round(H_vs_lg,3),seq_lift=round(seq_lift,3),
     epa=round(epa_play,3))])
cat("\nDONE\n")
