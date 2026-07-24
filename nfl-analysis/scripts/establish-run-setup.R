# Does "establishing the run" set up the PASS the way fans mean it: run on
# 1st and 2nd, then throw on 3rd? Test the 3rd-down dropback by the 1st and
# 2nd down history, WITHIN each 3rd-down distance (the key control: how you
# reached 3rd down sets the distance you face).
# Verdict: running twice does not open the 3rd-down pass; if anything it
# trails passing twice at the distances that matter.
suppressMessages({library(data.table); library(ggplot2); library(scales)})
setDTthreads(4)
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")
ROOT <- "/Users/nick/stranger9977/nfl-analysis"
d <- as.data.table(readRDS(file.path(ROOT,"data/pbp_slim.rds")))

keep <- d[(qb_dropback==1 | rush==1) & !is.na(epa) & !is.na(down) &
          (is.na(qb_kneel)|qb_kneel!=1) & (is.na(qb_spike)|qb_spike!=1) &
          season>=2015 & vegas_wp>=0.10 & vegas_wp<=0.90 &
          half_seconds_remaining>120,
          .(game_id,posteam,drive,series,down,ydstogo,
            qb_dropback,rush,epa,first_down,play_id)]
keep[, call := ifelse(qb_dropback==1,"P", ifelse(rush==1,"R",NA))]
keep <- keep[!is.na(call)]
setorder(keep, game_id, posteam, drive, series, play_id)

fr <- function(v) v[1]
d1 <- keep[down==1, .(c1=fr(call)), by=.(game_id,posteam,drive,series)]
d2 <- keep[down==2, .(c2=fr(call)), by=.(game_id,posteam,drive,series)]
d3 <- keep[down==3, .(c3=fr(call), togo3=fr(ydstogo), epa3=fr(epa),
                      conv3=fr(first_down)), by=.(game_id,posteam,drive,series)]
S <- Reduce(function(a,b) merge(a,b,by=c("game_id","posteam","drive","series")),
            list(d1,d2,d3))
S <- S[!is.na(c1)&!is.na(c2)&!is.na(c3) & c3=="P"]
S[, hist := paste0(c1,c2)]
S[, togo_b := cut(togo3, c(0,2,4,7,10,100),
                  labels=c("3rd & 1-2","3rd & 3-4","3rd & 5-7","3rd & 8-10","3rd & 11+"),
                  right=TRUE)]

boot <- function(x,B=2000){bs<-replicate(B,mean(x[sample.int(length(x),replace=TRUE)]))
  c(m=mean(x),lo=quantile(bs,.025,names=FALSE),hi=quantile(bs,.975,names=FALSE),n=length(x))}
tab <- S[hist %in% c("RR","PP"), as.list(boot(epa3)), by=.(togo_b,hist)]
tab[, hist := factor(hist, levels=c("PP","RR"),
     labels=c("Passed on 1st & 2nd","Ran on 1st & 2nd"))]
tab[, togo_b := factor(togo_b, levels=rev(levels(S$togo_b)))]
print(tab[order(togo_b,hist)])

# difference labels (RR - PP) per bucket
wd <- dcast(S[hist%in%c("RR","PP")], togo_b~hist, value.var="epa3", fun=mean)
wd[, diff := RR-PP]
print(wd)

col_pass <- pal_cat[1]   # blue
col_run  <- pal_cat[2]   # orange
pos <- tab[, .(xmin=min(m), xmax=max(m)), by=togo_b]

p <- ggplot(tab, aes(m, togo_b)) +
  geom_vline(xintercept=0, color=col_baseline, linewidth=.4) +
  geom_line(aes(group=togo_b), color="#c3c2b7", linewidth=1.6, lineend="round") +
  geom_point(aes(color=hist), size=4.4) +
  geom_text(data=tab[hist=="Passed on 1st & 2nd"],
            aes(label=number(m,.01,style_positive="plus")), color=col_pass,
            vjust=-1.35, size=3.25, fontface="bold", family="sans") +
  geom_text(data=tab[hist=="Ran on 1st & 2nd"],
            aes(label=number(m,.01,style_positive="plus")), color=col_run,
            vjust=-1.35, size=3.25, fontface="bold", family="sans") +
  scale_color_manual(values=c("Passed on 1st & 2nd"=col_pass,"Ran on 1st & 2nd"=col_run),
                     name=NULL) +
  scale_x_continuous(limits=c(-0.24,0.14), breaks=seq(-0.2,0.1,.1),
                     labels=number_format(.01,style_positive="plus")) +
  labs(
    title="Grinding the run doesn't open up the third-down pass",
    subtitle="Expected points added on third-down dropbacks, split by what the offense did on first and second down,\nwithin each third-down distance. If establishing the run worked, the orange dots would sit to the right of the blue.\nThey don't: teams that passed twice throw a little better on the downs that decide drives.",
    x="EPA on the third-down pass", y=NULL,
    caption="nflverse play-by-play, 2015-2025, competitive snaps (win prob 10-90%), first snap of each down in a series. 95% bootstrap intervals.\nSamples per point range 666 to 2,549. Companion to the first-order test: even one drive of accumulated runs leaves the next pass no better once distance is held fixed."
  ) +
  theme_nfl() +
  theme(legend.position="top", legend.justification="left",
        plot.caption=element_text(lineheight=1.15))
save_chart(p, "establish-run-setup", width=10, height=6.4)
cat("\n3rd-and-medium (3-7) four-way:\n")
print(S[togo3>=3&togo3<=7,.(epa=round(mean(epa3),3),n=.N),by=hist][order(-epa)])
