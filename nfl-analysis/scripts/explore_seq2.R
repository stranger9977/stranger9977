library(data.table)
pbp <- as.data.table(readRDS("/home/user/stranger9977/nfl-analysis/data/pbp_slim.rds"))
pbp <- pbp[!is.na(vegas_wp) & vegas_wp >= 0.05 & vegas_wp <= 0.95]
pbp <- pbp[qb_kneel != 1 & qb_spike != 1]
pbp <- pbp[play_type != "no_play" & !is.na(play_type)]
pbp[, called_pass := as.integer(qb_dropback == 1)]
pbp[, called_run  := as.integer(rush == 1 & qb_dropback != 1)]
pbp <- pbp[called_pass == 1 | called_run == 1]
pbp[, calltype := ifelse(called_pass == 1, "pass", "run")]
pbp <- pbp[!is.na(epa)]

# order within drive by play_id and get previous called play type (same game+drive)
setorder(pbp, game_id, play_id)
pbp[, prev_call := shift(calltype), by=.(game_id, drive)]
pbp[, prev_epa  := shift(epa), by=.(game_id, drive)]
pbp[, prev_success := shift(success), by=.(game_id, drive)]

# focus: early-down (1st & 2nd) non-red-zone open-ish field, prev play exists
seq <- pbp[!is.na(prev_call) & down %in% c(1,2)]

cat("=== EARLY DOWN (1st/2nd), current call EPA by previous call ===\n")
t1 <- seq[, .(n=.N, epa=round(mean(epa),3), sr=round(mean(success),3)), by=.(down, calltype, prev_call)][order(down, calltype, prev_call)]
print(t1)

cat("\n=== Does prev run boost next PASS (play-action / establish run) ? by field zone ===\n")
seq[, zone := fifelse(yardline_100<=20,"redzone", fifelse(yardline_100<=50,"opp_half","own_half"))]
t2 <- seq[calltype=="pass", .(n=.N, pass_epa=round(mean(epa),3), sr=round(mean(success),3)), by=.(zone, prev_call)][order(zone, prev_call)]
print(t2)

cat("\n=== next-play MIX: after prev run vs prev pass, what do they call? (early down) ===\n")
t3 <- seq[, .(n=.N, pass_rate=round(mean(calltype=="pass"),3), next_epa=round(mean(epa),3)), by=.(down, prev_call)][order(down, prev_call)]
print(t3)

cat("\n=== 1st&10 only, prev-call effect on next call EPA (both current pass and run) ===\n")
s110 <- seq[down==1 & ydstogo==10]
t4 <- s110[, .(n=.N, epa=round(mean(epa),3), sr=round(mean(success),3)), by=.(calltype, prev_call)][order(calltype, prev_call)]
print(t4)
# gap for current pass: prev_run - prev_pass
pa_run  <- s110[calltype=="pass" & prev_call=="run"]
pa_pass <- s110[calltype=="pass" & prev_call=="pass"]
d <- mean(pa_run$epa)-mean(pa_pass$epa)
se <- sqrt(var(pa_run$epa)/nrow(pa_run)+var(pa_pass$epa)/nrow(pa_pass))
cat(sprintf("\n1st&10 PASS after run vs after pass: %.3f vs %.3f  diff=%.3f (95%% CI %.3f..%.3f)\n",
    mean(pa_run$epa), mean(pa_pass$epa), d, d-1.96*se, d+1.96*se))
ra_run  <- s110[calltype=="run" & prev_call=="run"]
ra_pass <- s110[calltype=="run" & prev_call=="pass"]
d2 <- mean(ra_run$epa)-mean(ra_pass$epa)
se2 <- sqrt(var(ra_run$epa)/nrow(ra_run)+var(ra_pass$epa)/nrow(ra_pass))
cat(sprintf("1st&10 RUN after run vs after pass:  %.3f vs %.3f  diff=%.3f (95%% CI %.3f..%.3f)\n",
    mean(ra_run$epa), mean(ra_pass$epa), d2, d2-1.96*se2, d2+1.96*se2))

cat("\n=== control for down&distance: 2nd down by ydstogo bucket, pass epa by prev call ===\n")
seq[, dist := fifelse(ydstogo<=3,"short(1-3)", fifelse(ydstogo<=7,"med(4-7)","long(8+)"))]
t5 <- seq[down==2 & calltype=="pass", .(n=.N, pass_epa=round(mean(epa),3)), by=.(dist, prev_call)][order(dist, prev_call)]
print(t5)
