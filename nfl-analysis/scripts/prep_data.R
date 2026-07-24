# Build a slim combined play-by-play file (2015-2025) with the columns most
# analyses need, so downstream scripts load in seconds. Full per-season files
# remain in data/ for anything needing extra columns (use fread select=).
suppressMessages(library(data.table))

dir <- local({
  cands <- c("/Users/nick/stranger9977/nfl-analysis/data",
             "/home/user/stranger9977/nfl-analysis/data")
  hit <- cands[dir.exists(cands)]
  if (length(hit)) hit[1] else file.path(getwd(), "data")
})
cols <- c(
  "play_id","game_id","season","week","season_type","home_team","away_team",
  "posteam","defteam","qtr","down","ydstogo","yardline_100","goal_to_go",
  "quarter_seconds_remaining","half_seconds_remaining","game_seconds_remaining",
  "play_type","yards_gained","shotgun","no_huddle","qb_dropback","qb_scramble",
  "pass","rush","special","pass_length","pass_location","air_yards",
  "yards_after_catch","run_location","run_gap","complete_pass","incomplete_pass",
  "interception","sack","touchdown","pass_touchdown","rush_touchdown",
  "first_down","first_down_pass","first_down_rush","third_down_converted",
  "third_down_failed","fourth_down_converted","fourth_down_failed",
  "ep","epa","air_epa","yac_epa","qb_epa","xyac_epa","xyac_mean_yardage",
  "wp","wpa","vegas_wp","vegas_wpa","success","cp","cpoe","xpass","pass_oe",
  "score_differential","posteam_score","defteam_score",
  "posteam_timeouts_remaining","defteam_timeouts_remaining",
  "passer_player_id","passer_player_name","receiver_player_id",
  "receiver_player_name","rusher_player_id","rusher_player_name",
  "kicker_player_id","kicker_player_name","punter_player_id","punter_player_name",
  "field_goal_result","field_goal_attempt","kick_distance","extra_point_attempt",
  "two_point_attempt","two_point_conv_result","punt_attempt","kickoff_attempt",
  "punt_blocked","touchback","return_yards","penalty","penalty_type",
  "penalty_team","penalty_yards","fumble_lost","drive","series","series_success",
  "series_result","roof","surface","temp","wind","spread_line","total_line",
  "timeout","timeout_team","play_clock","st_play_type","qb_kneel","qb_spike"
)

files <- sprintf(file.path(dir, "play_by_play_%d.csv.gz"), 2015:2025)
pbp <- rbindlist(lapply(files, function(f) {
  hdr <- names(fread(f, nrows = 0))
  fread(f, select = intersect(cols, hdr), showProgress = FALSE)
}), fill = TRUE)

saveRDS(pbp, file.path(dir, "pbp_slim.rds"), compress = FALSE)
cat("Rows:", nrow(pbp), "Cols:", ncol(pbp), "\n")
cat("Size:", round(file.size(file.path(dir, "pbp_slim.rds"))/1e6), "MB\n")
