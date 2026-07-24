# Does a bigger OR better run game early open up passing OR running later?
# Answered in three metrics (EPA, success rate, win probability added) so the
# infographic can toggle. Every version lands on zero.
suppressMessages({library(data.table); library(ggplot2); library(scales)})
setDTthreads(4)
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")
ROOT <- "/Users/nick/stranger9977/nfl-analysis"
d <- as.data.table(readRDS(file.path(ROOT,"data/pbp_slim.rds")))
d <- d[season>=2015 & (qb_dropback==1|rush==1) & !is.na(epa) & !is.na(down) &
       (is.na(qb_kneel)|qb_kneel!=1) & (is.na(qb_spike)|qb_spike!=1) & !is.na(posteam)]
d[, is_pass := as.integer(qb_dropback==1)]
d[, is_run  := as.integer(rush==1 & qb_dropback==0)]

early <- d[qtr<=2, .(h1_att=sum(is_run), h1_run_succ=mean(success[is_run==1])),
           by=.(game_id,posteam,season)]
late <- function(who){ dd<-d[qtr%in%3:4 & get(who)==1 & vegas_wp>=0.2 & vegas_wp<=0.8,
     .(epa=mean(epa), wpa=mean(wpa,na.rm=TRUE), succ=mean(success), n=.N), by=.(game_id,posteam)]
  setnames(dd, c("epa","wpa","succ","n"), paste0(substr(who,4,4),"_",c("epa","wpa","succ","n"))); dd }
M <- Reduce(function(a,b) merge(a,b,by=c("game_id","posteam"),all.x=TRUE),
            list(early, late("is_pass"), late("is_run")))

bootr <- function(x,y,B=3000){ok<-is.finite(x)&is.finite(y); x<-x[ok];y<-y[ok];n<-length(x)
  bs<-replicate(B,{i<-sample.int(n,n,TRUE);cor(x[i],y[i])})
  data.table(r=cor(x,y), lo=quantile(bs,.025,names=FALSE), hi=quantile(bs,.975,names=FALSE), n=n)}

METR <- list(
  epa  = list(suf="epa",  nm="EPA per play",              file="epa"),
  succ = list(suf="succ", nm="success rate",              file="success"),
  wpa  = list(suf="wpa",  nm="win probability added",     file="wpa"))

for (mk in names(METR)) {
  m <- METR[[mk]]; ps<-paste0("p_",m$suf); rs<-paste0("r_",m$suf)
  rows <- rbindlist(list(
    cbind(lab="Ran a LOT early\ncarries in H1  ->  passing later",  bootr(M[p_n>=8]$h1_att, M[p_n>=8][[ps]])),
    cbind(lab="Ran a LOT early\ncarries in H1  ->  running later",  bootr(M[r_n>=6]$h1_att, M[r_n>=6][[rs]])),
    cbind(lab="Ran WELL early\nrun success in H1  ->  passing later", bootr(M[p_n>=8]$h1_run_succ, M[p_n>=8][[ps]])),
    cbind(lab="Ran WELL early\nrun success in H1  ->  running later", bootr(M[r_n>=6]$h1_run_succ, M[r_n>=6][[rs]]))))
  rows[, yi := (nrow(rows):1)]
  p <- ggplot(rows, aes(r, yi)) +
    annotate("rect", xmin=-0.05, xmax=0.05, ymin=0.4, ymax=4.7, fill=pal_cat[1], alpha=0.08) +
    annotate("text", x=0, y=4.72, label="no effect", vjust=-0.1, size=2.9, color=ink_muted, family="mono") +
    geom_vline(xintercept=0, color=col_baseline, linewidth=0.5) +
    annotate("segment", x=0.11, xend=0.24, y=4.5, yend=4.5,
             arrow=arrow(length=unit(0.16,"cm"),type="closed"), color=ink_muted, linewidth=0.4) +
    annotate("text", x=0.11, y=4.5, label='what "establishing the run" should do',
             hjust=-0.02, vjust=-0.9, size=2.9, color=ink_secondary, family="mono") +
    geom_errorbar(aes(xmin=lo,xmax=hi), orientation="y", width=0, linewidth=0.7, color=pal_cat[1], alpha=0.5) +
    geom_point(size=4.3, color=pal_cat[1]) +
    geom_text(aes(label=number(r,.01,style_positive="plus")), vjust=-1.25, size=3.3,
              fontface="bold", color=ink_primary, family="sans") +
    scale_y_continuous(breaks=rows$yi, labels=rows$lab, limits=c(0.4,5.0), expand=expansion(0)) +
    scale_x_continuous(limits=c(-0.16,0.30), breaks=seq(-0.1,0.3,.1),
                       labels=number_format(.01,style_positive="plus")) +
    labs(title=sprintf("A good run game early opens nothing later (%s)", m$nm),
         subtitle="How strongly first-half running, by volume and by efficiency, predicts later passing and running, once game\nscript is stripped out. Whether a team ran a lot or ran well early, the payoff later is indistinguishable from zero.",
         x=sprintf("Correlation of early running with later play (%s)", m$nm), y=NULL,
         caption="nflverse play-by-play, 2015-2025. Later plays limited to neutral win probability 20-80%. 1,638 to 2,548 team-games per row. 95% bootstrap intervals.") +
    theme_nfl() + theme(axis.text.y=element_text(size=9,color=ink_secondary,lineheight=0.95),
                        plot.caption=element_text(lineheight=1.2))
  save_chart(p, paste0("establish-run-quality-", m$file), width=10, height=6.0)
  cat(mk, ":\n"); print(rows[,.(lab=gsub("\n"," ",lab), r=round(r,3))])
}
