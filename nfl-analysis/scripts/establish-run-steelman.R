# Steelman the run-first coach, then answer from the tape. Three charts:
#   1. steelman-pass-sets-run : the PASS earns light boxes; that opens the run
#   2. steelman-weardown      : defenses do not wear down (flat by quarter)
#   3. steelman-cold          : December football, the one kernel of truth
suppressMessages({library(data.table); library(ggplot2); library(scales)})
setDTthreads(4)
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")
ROOT <- "/Users/nick/stranger9977/nfl-analysis"
d <- as.data.table(readRDS(file.path(ROOT,"data/pbp_slim.rds")))
d <- d[season>=2015 & (qb_dropback==1|rush==1) & !is.na(epa) & !is.na(down) &
       (is.na(qb_kneel)|qb_kneel!=1) & (is.na(qb_spike)|qb_spike!=1) & !is.na(posteam)]
d[, is_pass := as.integer(qb_dropback==1)]
d[, is_run  := as.integer(rush==1 & qb_dropback==0)]
bmean <- function(x,B=2000){bs<-replicate(B,mean(sample(x,length(x),TRUE)))
  c(m=mean(x), lo=quantile(bs,.025,names=FALSE), hi=quantile(bs,.975,names=FALSE))}

## ---- CHART 1: the pass sets up the run (light boxes) -------------------
box <- rbindlist(lapply(2016:2023, function(y){
  z<-fread(sprintf("%s/data/pbp_participation_%d.csv.gz",ROOT,y),
           select=c("nflverse_game_id","play_id","defenders_in_box"))
  setnames(z,"nflverse_game_id","game_id"); z}))
r <- merge(d[is_run==1 & down<=2, .(game_id,play_id,posteam,season,success)],
           box[!is.na(defenders_in_box)&defenders_in_box>0], by=c("game_id","play_id"))
r[, box_b := factor(fifelse(defenders_in_box<=6,"Light box\n(6 or fewer)",
              fifelse(defenders_in_box==7,"Even box\n(7)","Stacked box\n(8 or more)")),
              levels=c("Stacked box\n(8 or more)","Even box\n(7)","Light box\n(6 or fewer)"))]
b1 <- r[, as.list(bmean(success)), by=box_b]
b1[, n := r[, .N, by=box_b]$N[match(box_b, r[, .N, by=box_b]$box_b)]]
# passing earns light boxes (team-season)
tr <- r[, .(box=mean(defenders_in_box), n=.N), by=.(posteam,season)][n>=100]
tp <- d[down<=2, .(passrate=mean(is_pass)), by=.(posteam,season)]
TT <- merge(tr,tp,by=c("posteam","season")); rbox <- cor(TT$passrate,TT$box)
print(b1)
p1 <- ggplot(b1, aes(m, box_b)) +
  geom_col(fill=pal_cat[1], width=.62, alpha=.92) +
  geom_errorbar(aes(xmin=lo,xmax=hi), orientation="y", width=.18, linewidth=.5, color=ink_secondary) +
  geom_text(aes(x=hi, label=percent(m,1)), hjust=-0.5, size=3.6, fontface="bold", color=ink_primary) +
  scale_x_continuous(labels=percent, limits=c(0,0.47), expand=expansion(c(0,0))) +
  labs(title="The pass sets up the run, not the other way around",
       subtitle="Success rate of early-down runs by how many defenders are in the box. Runs work when the box is light,\nand a light box is something the passing game earns: the more a team passes, the lighter the boxes it sees.",
       x="Early-down run success rate", y=NULL,
       caption=sprintf("nflverse play-by-play with participation charting, 2016-2023 (n = 20,857 to 38,654 runs per box). 95%% bootstrap intervals.\nAcross 256 team-seasons, early-down pass rate vs the average box a team's runs face correlates r = %+.2f: heavier passing, lighter boxes.", rbox)) +
  theme_nfl() + theme(axis.text.y=element_text(size=10,color=ink_secondary,lineheight=.9))
save_chart(p1, "steelman-pass-sets-run", width=10, height=5.6)

## ---- CHART 2: defenses do not wear down --------------------------------
wd <- d[is_run==1 & qtr<=4 & vegas_wp>=0.2 & vegas_wp<=0.8,
        as.list(bmean(success)), by=qtr][order(qtr)]
print(wd)
p2 <- ggplot(wd, aes(qtr, m)) +
  annotate("segment", x=1, xend=4, y=wd$m[1], yend=wd$m[1]+0.06,
           linetype="22", color=ink_muted, linewidth=.5) +
  annotate("text", x=2.5, y=wd$m[1]+0.052, label="if defenses wore down, late runs would climb",
           size=3, color=ink_muted, family="mono", vjust=-0.4) +
  geom_ribbon(aes(ymin=lo,ymax=hi), fill=pal_cat[2], alpha=.14) +
  geom_line(color=pal_cat[2], linewidth=1.2) + geom_point(color=pal_cat[2], size=3.2) +
  geom_text(aes(label=percent(m,1)), vjust=-1.4, size=3.3, fontface="bold", color=ink_primary) +
  scale_x_continuous(breaks=1:4, labels=paste0("Q",1:4)) +
  scale_y_continuous(labels=percent, limits=c(0.36,0.48)) +
  labs(title="Defenses don't wear down: late runs are no better than early ones",
       subtitle="Run success rate by quarter in neutral game states. The line is flat. A team's fourth-quarter run efficiency\nis also unrelated to how much it ran in the first half (correlation +0.00), so pounding it early buys nothing late.",
       x=NULL, y="Run success rate",
       caption="nflverse play-by-play, 2015-2025, neutral win probability 20-80% (so leading teams running out the clock don't skew it).\n10,580 to 29,734 runs per quarter. 95% bootstrap intervals.") +
  theme_nfl()
save_chart(p2, "steelman-weardown", width=10, height=5.6)

## ---- CHART 3: December football, the one kernel of truth ----------------
w <- d[roof=="outdoors" & !is.na(temp)]
w[, temp_b := cut(temp, c(-20,25,35,45,55,70,120),
                  labels=c("25 or below","26-35","36-45","46-55","56-70","above 70"))]
cg <- w[, {pg<-mean(epa[is_pass==1])-mean(epa[is_run==1])
           bs<-replicate(2000,{i<-sample(.N,.N,TRUE)
             mean(epa[i][is_pass[i]==1])-mean(epa[i][is_run[i]==1])})
           .(gap=pg, lo=quantile(bs,.025,names=FALSE), hi=quantile(bs,.975,names=FALSE), n=.N)},
         by=temp_b][order(temp_b)]
print(cg)
p3 <- ggplot(cg, aes(as.integer(temp_b), gap)) +
  annotate("rect", xmin=.5, xmax=6.5, ymin=-0.02, ymax=0, fill=pal_cat[2], alpha=.10) +
  geom_hline(yintercept=0, color=col_baseline, linewidth=.5) +
  annotate("text", x=1, y=0.004, label="below this line, running is the better call", hjust=0,
           vjust=-0.3, size=2.9, color=ink_muted, family="mono") +
  geom_ribbon(aes(ymin=lo,ymax=hi,group=1), fill=pal_cat[1], alpha=.13) +
  geom_line(aes(group=1), color=pal_cat[1], linewidth=1.2) +
  geom_point(color=pal_cat[1], size=3.2) +
  geom_text(aes(label=number(gap,.01,style_positive="plus")), vjust=-1.35, size=3.15,
            fontface="bold", color=ink_primary) +
  scale_x_continuous(breaks=1:6, labels=levels(cg$temp_b)) +
  scale_y_continuous(limits=c(-0.02,0.19), breaks=seq(0,0.15,.05),
                     labels=number_format(.01,style_positive="plus")) +
  labs(title="December football, the one place the run-first coach has a point",
       subtitle="How much better passing is than running (EPA per play) by game-time temperature, outdoors. In the deep cold the\npassing edge shrinks by three-quarters. But it never flips: throwing stays the better bet even below 25 degrees.",
       x="Game temperature (degrees F)", y="Passing edge over running (EPA per play)",
       caption="nflverse play-by-play, 2015-2025, outdoor games with recorded temperature (n = 8,340 to 66,587 plays per bucket). 95% bootstrap intervals.\nSame story in wind: the passing edge falls from +0.14 in calm air to +0.05 above 15 mph, and teams barely shift their run-pass mix for either.") +
  theme_nfl() + theme(axis.text.x=element_text(size=9))
save_chart(p3, "steelman-cold", width=10, height=5.8)
