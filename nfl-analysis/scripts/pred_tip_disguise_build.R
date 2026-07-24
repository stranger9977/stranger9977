# =====================================================================
# BUILD: pre-snap "tip" (disguise) table  ->  scratch/pred_tip_disguise.rds
# ---------------------------------------------------------------------
# Question: does the predictability paradox resolve via DISGUISE?
#   Lore: elite predictable callers run & pass from the SAME pre-snap
#   look, so a known tendency can't be exploited.
# Metric "presnap_tip" = extra run/pass certainty that formation +
#   personnel (the pre-snap LOOK) removes BEYOND down/distance/score.
#   presnap_tip = H_situ(matched plays) - H_look
#     H_situ = within-cell run/pass entropy (EB-shrunk, K=15)
#     H_look = within-(cell x look) run/pass entropy (EB-shrunk to the
#              caller's own shrunk cell rate, K=15)
#   LOW tip  = the look hides the call (disguise)
#   HIGH tip = the look telegraphs the call
# Window: 2016-2023 ONLY (nflverse participation formation coverage).
# Reproducible recipe mirrors predictability_build.R Hbin()+K=15.
# =====================================================================
suppressMessages(library(data.table))
setDTthreads(2)

ROOT <- "/Users/nick/stranger9977/nfl-analysis"
DATA <- file.path(ROOT, "data")
OUT  <- file.path(ROOT, "scratch")
SC   <- "/private/tmp/claude-501/-Users-nick-stranger9977/fa82bd70-8c03-4970-9197-8f31c9f58176/scratchpad"

Hbin <- function(p){ p <- pmin(pmax(p,1e-9),1-1e-9); -(p*log2(p)+(1-p)*log2(1-p)) }
K <- 15  # empirical-Bayes shrinkage strength (same as predictability_build.R)

# ---- 1. Canonical caller-attributed plays (2016-2023) ----------------
d <- as.data.table(readRDS(file.path(OUT, "pred_plays.rds")))
d <- d[season >= 2016 & season <= 2023]

# ---- 2. Attach the pre-snap LOOK from participation files ------------
part <- rbindlist(lapply(2016:2023, function(y){
  p <- fread(file.path(DATA, sprintf("pbp_participation_%d.csv.gz", y)),
             select = c("nflverse_game_id","play_id",
                        "offense_formation","offense_personnel"))
  setnames(p, "nflverse_game_id", "game_id")
  p
}))
d <- merge(d, part, by = c("game_id","play_id"), all.x = TRUE)

# formation NA handling: drop plays with no charted formation (these are
# the ~0.5% of 2016-2023 called plays the participation feed never coded).
n_pre <- nrow(d)
d <- d[!is.na(offense_formation) & offense_formation != ""]
cat(sprintf("dropped %d of %d plays lacking a charted formation (%.2f%%)\n",
            n_pre - nrow(d), n_pre, 100*(n_pre-nrow(d))/n_pre))

# personnel bucket: collapse "n RB, n TE, n WR" into the common groupings
pers_bucket <- function(x){
  rb <- as.integer(sub(".*?([0-9]+) RB.*", "\\1", x)); rb[is.na(rb)] <- 1L
  te <- as.integer(sub(".*?([0-9]+) TE.*", "\\1", x)); te[is.na(te)] <- 1L
  fifelse(rb==1 & te==1, "11",
  fifelse(rb==1 & te==2, "12",
  fifelse(rb==2 & te==1, "21",
  fifelse(rb==1 & te==3, "13",
  fifelse(rb==0,        "empty", "other")))))
}
d[, pbk := pers_bucket(offense_personnel)]
d[offense_formation=="EMPTY", pbk := "empty"]
d[, look := paste(offense_formation, pbk, sep=":")]

# ---- 3. Situation entropy on the SAME (formation-coded) plays --------
#  shrink caller's within-cell pass rate toward the LEAGUE cell rate lg_p
cs_cell <- d[, .(n_cell=.N, p_raw=mean(is_pass), lg_p=lg_p[1]),
             by=.(off_play_caller, cell)]
cs_cell[, p_shr := (n_cell*p_raw + K*lg_p)/(n_cell + K)]
cs_cell[, H_cell := Hbin(p_shr)]

# ---- 4. Look entropy: within (cell x look), shrunk to caller cell rate
cs_look <- d[, .(n_cl=.N, p_raw=mean(is_pass)),
             by=.(off_play_caller, cell, look)]
cs_look <- merge(cs_look, cs_cell[,.(off_play_caller,cell,p_shr_cell=p_shr)],
                 by=c("off_play_caller","cell"), all.x=TRUE)
cs_look[, p_shr := (n_cl*p_raw + K*p_shr_cell)/(n_cl + K)]
cs_look[, H_cl := Hbin(p_shr)]

# ---- 5. Aggregate to caller (weight cells/looks by play counts) ------
agg_situ <- cs_cell[, .(H_situ_m = sum(H_cell*n_cell)/sum(n_cell),
                        n_look   = sum(n_cell),
                        pass_rate= sum(p_raw*n_cell)/sum(n_cell)),
                    by=off_play_caller]
agg_look <- cs_look[, .(H_look = sum(H_cl*n_cl)/sum(n_cl)), by=off_play_caller]
tip <- merge(agg_situ, agg_look, by="off_play_caller")
tip[, presnap_tip := H_situ_m - H_look]

# ---- 6. Bring in CAREER offense + situational predictability ---------
career <- as.data.table(readRDS(file.path(OUT, "pred_career.rds")))
tip <- merge(tip, career[, .(off_play_caller, guess_xs, H_vs_lg,
                             epa_play, n_plays_car=n_plays, last_season)],
             by="off_play_caller")

# ---- 7. QB confound control: career cpoe on the caller's dropbacks ----
# qb_cpoe lives per caller-season in tab_qb.rds (see caller-vs-qb.R);
# collapse to career weighting by dropbacks n_db.
qb <- as.data.table(readRDS(file.path(SC, "tab_qb.rds")))
qb_car <- qb[!is.na(qb_cpoe) & !is.na(n_db),
             .(qb_cpoe = sum(qb_cpoe*n_db)/sum(n_db)), by=off_play_caller]
tip <- merge(tip, qb_car, by="off_play_caller", all.x=TRUE)

setorder(tip, presnap_tip)
saveRDS(tip, file.path(OUT, "pred_tip_disguise.rds"))
cat("saved", nrow(tip), "callers ->", file.path(OUT,"pred_tip_disguise.rds"), "\n\n")

# =====================================================================
# HONEST RE-TEST of r(tip, EPA): is the low-tip "disguise" cluster real,
# or a small-n / shrinkage artifact?  (reviewer points 2, 3, 5)
# =====================================================================
report <- function(sub, tag){
  if (nrow(sub) < 5) { cat(tag, ": n<5, skip\n"); return(invisible()) }
  r  <- cor(sub$presnap_tip, sub$epa_play)
  rs <- cor(sub$presnap_tip, sub$epa_play, method="spearman")
  cat(sprintf("%-42s n=%2d  r(tip,EPA)=%+.3f  Spearman=%+.3f\n",
              tag, nrow(sub), r, rs))
}
cat("=== raw / floor sensitivity ===\n")
report(tip[n_look>=500],  "floor n>=500  (published)")
report(tip[n_look>=1500], "floor n>=1500")
report(tip[n_look>=2500], "floor n>=2500 (comparably sampled)")
report(tip[n_look>=4000], "floor n>=4000")

# partial r controlling log(n_look) -- does tip survive the n artifact?
pcor <- function(x,y,z){ rxy<-cor(x,y); rxz<-cor(x,z); ryz<-cor(y,z);
                         (rxy-rxz*ryz)/sqrt((1-rxz^2)*(1-ryz^2)) }
s <- tip[n_look>=500 & !is.na(epa_play)]
cat("\n=== n-artifact controls (floor 500) ===\n")
cat(sprintf("r(tip, log n_look)       = %+.3f\n", cor(s$presnap_tip, log(s$n_look))))
cat(sprintf("r(EPA, log n_look)       = %+.3f\n", cor(s$epa_play,    log(s$n_look))))
cat(sprintf("partial r(tip,EPA|log n) = %+.3f\n", pcor(s$presnap_tip, s$epa_play, log(s$n_look))))
m <- lm(epa_play ~ presnap_tip + log(n_look), data=s)
cat("OLS EPA ~ tip + log(n_look):\n"); print(round(summary(m)$coefficients,4))

# QB confound (point 5)
sq <- s[!is.na(qb_cpoe)]
cat(sprintf("\n=== QB confound (floor 500, n=%d w/ cpoe) ===\n", nrow(sq)))
cat(sprintf("r(tip, qb_cpoe)          = %+.3f\n", cor(sq$presnap_tip, sq$qb_cpoe)))
cat(sprintf("partial r(tip,EPA|cpoe)  = %+.3f\n", pcor(sq$presnap_tip, sq$epa_play, sq$qb_cpoe)))
mq <- lm(epa_play ~ presnap_tip + log(n_look) + qb_cpoe, data=sq)
cat("OLS EPA ~ tip + log(n_look) + qb_cpoe:\n"); print(round(summary(mq)$coefficients,4))

# who is in the low-tip cluster, and how big is their sample? (point 3)
cat("\n=== lowest-tip 'disguise' cluster: are they small-n? ===\n")
print(tip[n_look>=500][order(presnap_tip)][1:8,
      .(off_play_caller, n_look, presnap_tip=round(presnap_tip,4),
        epa_play=round(epa_play,3))])
cat("\nmedian n_look, whole field:", median(tip[n_look>=500]$n_look),
    "| median n_look, bottom-tip decile:",
    median(tip[n_look>=500][order(presnap_tip)][1:8]$n_look), "\n")
cat("DONE\n")
