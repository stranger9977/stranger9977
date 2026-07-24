library(data.table)
pbp <- as.data.table(readRDS("/home/user/stranger9977/nfl-analysis/data/pbp_slim.rds"))

# ---- base filters ----
pbp <- pbp[!is.na(vegas_wp) & vegas_wp >= 0.05 & vegas_wp <= 0.95]
pbp <- pbp[qb_kneel != 1 & qb_spike != 1]
pbp <- pbp[play_type != "no_play" & !is.na(play_type)]
# called pass = dropback (incl scrambles); called run = rush & not dropback
pbp[, called_pass := as.integer(qb_dropback == 1)]
pbp[, called_run  := as.integer(rush == 1 & qb_dropback != 1)]
pbp <- pbp[called_pass == 1 | called_run == 1]
pbp[, calltype := ifelse(called_pass == 1, "pass", "run")]
pbp <- pbp[!is.na(epa)]
cat("rows after filter:", nrow(pbp), "\n")

# helper: summarize pass vs run for a subset with a down-bucket column
summ <- function(dt, label){
  dt[, .(
    n_pass = sum(calltype=="pass"),
    n_run  = sum(calltype=="run"),
    epa_pass = mean(epa[calltype=="pass"]),
    epa_run  = mean(epa[calltype=="run"]),
    sd_pass  = sd(epa[calltype=="pass"]),
    sd_run   = sd(epa[calltype=="run"]),
    sr_pass  = mean(success[calltype=="pass"]),
    sr_run   = mean(success[calltype=="run"]),
    pass_rate = mean(calltype=="pass")
  ), by=bucket][, slice := label][]
}

results <- list()

# 1. open field 1st-and-10 (own20 to opp40): yardline 40-80
of <- pbp[yardline_100>=40 & yardline_100<=80 & down==1 & ydstogo==10]
of[, bucket := "1st&10"]
results[["openfield"]] <- summ(of, "Open field (own20-opp40)")

# 2. red zone by down
rz <- pbp[yardline_100<=20]
rz[, bucket := paste0("down", down)]
results[["redzone"]] <- summ(rz[down %in% 1:4], "Red zone (<=20)")

# 3. goal to go inside 5 by down
g5 <- pbp[goal_to_go==1 & yardline_100<=5]
g5[, bucket := paste0("down", down)]
results[["goal5"]] <- summ(g5[down %in% 1:4], "Goal-to-go inside 5")

# 4. short yardage 3rd/4th & 1-2
sy <- pbp[down %in% c(3,4) & ydstogo %in% c(1,2)]
sy[, bucket := paste0("down", down, "_", ydstogo)]
results[["short"]] <- summ(sy, "Short yardage 3rd/4th&1-2")

# 5. high leverage late: 2nd half, one-score, <5:00
hl <- pbp[qtr>=3 & abs(score_differential)<=8 & game_seconds_remaining<300]
hl[, bucket := paste0("down", down)]
results[["highlev"]] <- summ(hl[down %in% 1:4], "High-lev late (2H,1score,<5min)")

# 6. two-minute offense
tm <- pbp[half_seconds_remaining<=120]
tm[, bucket := paste0("down", down)]
results[["twomin"]] <- summ(tm[down %in% 1:4], "Two-minute offense")

allr <- rbindlist(results)
allr[, gap := epa_pass - epa_run]
# SE of difference in means
allr[, se_gap := sqrt(sd_pass^2/n_pass + sd_run^2/n_run)]
allr[, ci_lo := gap - 1.96*se_gap]
allr[, ci_hi := gap + 1.96*se_gap]
setcolorder(allr, c("slice","bucket","n_pass","n_run","epa_pass","epa_run","gap","se_gap","ci_lo","ci_hi","sr_pass","sr_run","pass_rate"))
options(width=200)
print(allr[, .(slice,bucket,n_pass,n_run,epa_pass=round(epa_pass,3),epa_run=round(epa_run,3),gap=round(gap,3),ci_lo=round(ci_lo,3),ci_hi=round(ci_hi,3),sr_pass=round(sr_pass,3),sr_run=round(sr_run,3),pass_rate=round(pass_rate,3))])
saveRDS(allr, "/tmp/claude-0/-home-user-stranger9977/f03221fa-fab0-55bd-bf7a-5b49b7ec5a63/scratchpad/slice_tab.rds")
