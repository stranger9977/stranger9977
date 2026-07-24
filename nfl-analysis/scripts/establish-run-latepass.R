# Does establishing the run EARLY open up the pass LATER (later in H1, in H2,
# in Q4, and for play-action)? Answer: no, at every timescale.
# Each late-pass measure is restricted to neutral game script (win prob 20-80%)
# to strip out the fact that early-running teams are usually winning.
suppressMessages({library(data.table); library(ggplot2); library(scales)})
setDTthreads(4)
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")
ROOT <- "/Users/nick/stranger9977/nfl-analysis"
d <- as.data.table(readRDS(file.path(ROOT,"data/pbp_slim.rds")))
d <- d[season>=2015 & (qb_dropback==1|rush==1) & !is.na(epa) & !is.na(down) &
       (is.na(qb_kneel)|qb_kneel!=1) & (is.na(qb_spike)|qb_spike!=1) & !is.na(posteam)]
d[, is_pass := as.integer(qb_dropback==1)]
d[, is_run  := as.integer(rush==1 & qb_dropback==0)]

early <- d[qtr<=2, .(fh_run_att=sum(is_run), fh_run_epa=mean(epa[is_run==1])),
           by=.(game_id,posteam,season)]
q1 <- d[qtr==1, .(q1_run_att=sum(is_run)), by=.(game_id,posteam)]
lp <- function(dd) dd[is_pass==1 & vegas_wp>=0.2 & vegas_wp<=0.8,
                      .(epa=mean(epa), n=.N), by=.(game_id,posteam)]
h2<-lp(d[qtr%in%c(3,4)]); setnames(h2,c("epa","n"),c("h2","h2n"))
q4<-lp(d[qtr==4]);        setnames(q4,c("epa","n"),c("q4","q4n"))
q2<-lp(d[qtr==2]);        setnames(q2,c("epa","n"),c("q2","q2n"))
ftn <- rbindlist(lapply(2022:2024, function(y)
  fread(sprintf("%s/data/ftn_charting_%d.csv.gz",ROOT,y),
        select=c("nflverse_game_id","nflverse_play_id","is_play_action"))))
setnames(ftn,c("game_id","play_id","pa"))
dp <- merge(d[season>=2022 & is_pass==1,.(game_id,play_id,posteam,qtr,epa,vegas_wp)],
            ftn,by=c("game_id","play_id"))
pa <- dp[qtr%in%c(3,4)&vegas_wp>=0.2&vegas_wp<=0.8,
         .(pa_prem=mean(epa[pa==TRUE],na.rm=TRUE)-mean(epa[pa!=TRUE],na.rm=TRUE),
           npa=sum(pa==TRUE,na.rm=TRUE)), by=.(game_id,posteam)]
M <- Reduce(function(a,b) merge(a,b,by=c("game_id","posteam"),all.x=TRUE),
            list(early,q1,h2,q4,q2,pa))

bootr <- function(x,y,B=3000){
  ok<-is.finite(x)&is.finite(y); x<-x[ok]; y<-y[ok]; n<-length(x)
  bs<-replicate(B,{i<-sample.int(n,n,TRUE); cor(x[i],y[i])})
  list(r=cor(x,y), lo=quantile(bs,.025,names=FALSE), hi=quantile(bs,.975,names=FALSE), n=n)
}
rows <- rbindlist(list(
  data.table(lab="Later in the same half\nrun in Q1  ->  pass in Q2",       as.data.table(bootr(M[q2n>=5]$q1_run_att,  M[q2n>=5]$q2))),
  data.table(lab="The second half\nrun in H1  ->  pass in H2",              as.data.table(bootr(M[h2n>=8]$fh_run_att,  M[h2n>=8]$h2))),
  data.table(lab="The fourth quarter\nrun in H1  ->  pass in Q4",           as.data.table(bootr(M[q4n>=5]$fh_run_att,  M[q4n>=5]$q4))),
  data.table(lab="Even when the early runs worked\nrun EPA in H1  ->  pass in H2", as.data.table(bootr(M[h2n>=8]$fh_run_epa, M[h2n>=8]$h2))),
  data.table(lab="Play-action, the last resort claim\nearly runs  ->  H2 play-action edge", as.data.table(bootr(M[npa>=4]$fh_run_att, M[npa>=4]$pa_prem)))
))
rows[, yi := (nrow(rows):1)]          # top row = first
print(rows)

p <- ggplot(rows, aes(r, yi)) +
  annotate("rect", xmin=-0.05, xmax=0.05, ymin=0.4, ymax=5.75,
           fill=pal_cat[1], alpha=0.08) +
  annotate("text", x=0, y=5.78, label="no effect", vjust=-0.1, size=2.9,
           color=ink_muted, family="mono") +
  geom_vline(xintercept=0, color=col_baseline, linewidth=0.5) +
  annotate("segment", x=0.11, xend=0.24, y=5.5, yend=5.5,
           arrow=arrow(length=unit(0.16,"cm"), type="closed"),
           color=ink_muted, linewidth=0.4) +
  annotate("text", x=0.11, y=5.5, label='what "establishing the run" should do',
           hjust=-0.02, vjust=-0.9, size=2.9, color=ink_secondary, family="mono") +
  geom_errorbar(aes(xmin=lo, xmax=hi), orientation="y", width=0,
                linewidth=0.7, color=pal_cat[1], alpha=0.5) +
  geom_point(size=4.3, color=pal_cat[1]) +
  geom_text(aes(label=number(r,.01,style_positive="plus")), vjust=-1.25,
            size=3.3, fontface="bold", color=ink_primary, family="sans") +
  scale_y_continuous(breaks=rows$yi, labels=rows$lab, limits=c(0.4,6.0),
                     expand=expansion(0)) +
  scale_x_continuous(limits=c(-0.16,0.30), breaks=seq(-0.1,0.3,.1),
                     labels=number_format(.01,style_positive="plus")) +
  labs(
    title="Establishing the run early doesn't open up the pass later",
    subtitle="How strongly first-half running predicts later passing, once you strip out game script (neutral win\nprobability only). Every version of the claim, later in the half, the second half, the fourth quarter, even\nplay-action, lands on zero. Teams that ran more early passed a touch worse late, not better.",
    x="Correlation of early running with later passing efficiency", y=NULL,
    caption="nflverse play-by-play, 2015-2025. Late passes limited to win probability 20-80%, so garbage time and game script don't drive it.\n1,848 to 3,778 team-games per row; play-action row 321 (FTN charting 2022-2024). 95% bootstrap intervals.\nHolds within each team's own games too: all correlations sit within 0.03 of zero."
  ) +
  theme_nfl() +
  theme(axis.text.y=element_text(size=9.5, color=ink_secondary, lineheight=0.95),
        plot.caption=element_text(lineheight=1.2))
save_chart(p, "establish-run-latepass", width=10, height=6.6)
