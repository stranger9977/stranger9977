# Robustness + a new hole:
#  (1) Does the "establish the run" story change under WPA or success rate?
#  (2) Does a GOOD run game early (efficient rushing, not just volume) open
#      up the pass OR the run later?
suppressMessages({library(data.table)}); setDTthreads(4)
ROOT <- "/Users/nick/stranger9977/nfl-analysis"
d <- as.data.table(readRDS(file.path(ROOT,"data/pbp_slim.rds")))
d <- d[season>=2015 & (qb_dropback==1|rush==1) & !is.na(epa) & !is.na(down) &
       (is.na(qb_kneel)|qb_kneel!=1) & (is.na(qb_spike)|qb_spike!=1) & !is.na(posteam)]
d[, is_pass := as.integer(qb_dropback==1)]
d[, is_run  := as.integer(rush==1 & qb_dropback==0)]

## ============ ROBUSTNESS: 3rd-down RR vs PP in 3 metrics ==============
keep <- d[vegas_wp>=0.10 & vegas_wp<=0.90 & half_seconds_remaining>120,
          .(game_id,posteam,drive,series,down,ydstogo,is_pass,is_run,epa,wpa,success,first_down,play_id)]
keep[, call := ifelse(is_pass==1,"P",ifelse(is_run==1,"R",NA))]; keep<-keep[!is.na(call)]
setorder(keep, game_id, posteam, drive, series, play_id)
d1<-keep[down==1,.(c1=call[1]),by=.(game_id,posteam,drive,series)]
d2<-keep[down==2,.(c2=call[1]),by=.(game_id,posteam,drive,series)]
d3<-keep[down==3,.(c3=call[1],togo=ydstogo[1],epa=epa[1],wpa=wpa[1],succ=success[1]),by=.(game_id,posteam,drive,series)]
S<-Reduce(function(a,b)merge(a,b,by=c("game_id","posteam","drive","series")),list(d1,d2,d3))
S<-S[!is.na(c1)&!is.na(c2)&c3=="P"&togo>=3&togo<=7]; S[,hist:=paste0(c1,c2)]
cat("=== 3rd-and-medium pass after RR vs PP (the next-play test) ===\n")
print(S[hist%in%c("RR","PP"),.(epa=round(mean(epa),3), wpa=round(mean(wpa,na.rm=TRUE),4),
        succ=round(mean(succ),3), n=.N), by=hist][order(hist)])

## ============ long game: early run VOLUME -> later pass, 3 metrics =====
early<-d[qtr<=2,.(h1_att=sum(is_run), h1_run_succ=mean(success[is_run==1]),
                  h1_run_epa=mean(epa[is_run==1])), by=.(game_id,posteam,season)]
late<-function(dd,who) dd[get(who)==1 & vegas_wp>=0.2 & vegas_wp<=0.8,
     .(epa=mean(epa), wpa=mean(wpa,na.rm=TRUE), succ=mean(success), n=.N), by=.(game_id,posteam)]
h2p<-late(d[qtr%in%3:4],"is_pass"); setnames(h2p,c("epa","wpa","succ","n"),paste0("p_",c("epa","wpa","succ","n")))
h2r<-late(d[qtr%in%3:4],"is_run");  setnames(h2r,c("epa","wpa","succ","n"),paste0("r_",c("epa","wpa","succ","n")))
M<-Reduce(function(a,b)merge(a,b,by=c("game_id","posteam"),all.x=TRUE),list(early,h2p,h2r))
cr<-function(x,y,f){ok<-is.finite(x)&is.finite(y)&f; sprintf("r=%+.3f (n=%d)",cor(x[ok],y[ok]),sum(ok))}
cat("\n=== early run VOLUME (H1 carries) -> later PASS, 3 metrics ===\n")
cat("  EPA:    ",cr(M$h1_att,M$p_epa, M$p_n>=8),"\n")
cat("  WPA:    ",cr(M$h1_att,M$p_wpa,M$p_n>=8),"\n")
cat("  success:",cr(M$h1_att,M$p_succ,M$p_n>=8),"\n")

## ============ THE NEW HOLE: GOOD run game early -> later ==============
cat("\n=== GOOD early run game (H1 rush SUCCESS RATE) -> later PASS ===\n")
cat("  EPA:    ",cr(M$h1_run_succ,M$p_epa, M$p_n>=8),"\n")
cat("  WPA:    ",cr(M$h1_run_succ,M$p_wpa,M$p_n>=8),"\n")
cat("  success:",cr(M$h1_run_succ,M$p_succ,M$p_n>=8),"\n")
cat("=== GOOD early run game (H1 rush SUCCESS RATE) -> later RUN ===\n")
cat("  EPA:    ",cr(M$h1_run_succ,M$r_epa, M$r_n>=8),"\n")
cat("  WPA:    ",cr(M$h1_run_succ,M$r_wpa,M$r_n>=8),"\n")
cat("  success:",cr(M$h1_run_succ,M$r_succ,M$r_n>=8),"\n")
cat("=== GOOD early run game (H1 rush EPA) -> later PASS / RUN (EPA) ===\n")
cat("  -> later PASS EPA:",cr(M$h1_run_epa,M$p_epa,M$p_n>=8),"\n")
cat("  -> later RUN  EPA:",cr(M$h1_run_epa,M$r_epa,M$r_n>=8),"\n")
# within-team (kill team quality)
Z<-M[is.finite(h1_run_succ)&is.finite(p_epa)&p_n>=8]
Z[,`:=`(xd=h1_run_succ-mean(h1_run_succ), yd=p_epa-mean(p_epa)),by=.(posteam,season)]
cat("  within-team: good early run -> later pass EPA:",sprintf("r=%+.3f",cor(Z$xd,Z$yd)),"\n")
# bucket for the chart
M2<-M[is.finite(h1_run_succ)&p_n>=8&r_n>=6]
M2[,q:=cut(h1_run_succ,quantile(h1_run_succ,0:4/4,na.rm=TRUE),include.lowest=TRUE,
           labels=c("Worst early\nrun game","","","Best early\nrun game"))]
cat("\nLater efficiency by how GOOD the early run game was (quartiles):\n")
print(M2[,.(h1_run_succ=round(mean(h1_run_succ),3),
            later_pass_epa=round(mean(p_epa),3), later_pass_succ=round(mean(p_succ),3),
            later_run_epa=round(mean(r_epa),3),  later_run_succ=round(mean(r_succ),3),
            n=.N),by=q][order(q)])

## ============ predictability across metrics ===========================
cat("\n=== predictability (H_vs_lg) vs offense in 3 metrics ===\n")
pl<-as.data.table(readRDS(file.path(ROOT,"scratch/pred_plays.rds")))
teamq<-d[vegas_wp>=0.05&vegas_wp<=0.95,.(wpa=mean(wpa,na.rm=TRUE),succ=mean(success)),
         by=.(game_id,play_id)]
pl<-merge(pl,teamq,by=c("game_id","play_id"),all.x=TRUE)
tab<-as.data.table(readRDS(file.path(ROOT,"scratch/pred_tab.rds")))
cs_extra<-pl[,.(wpa=mean(wpa,na.rm=TRUE),succ=mean(succ,na.rm=TRUE)),by=cs]
tab<-merge(tab,cs_extra,by="cs",all.x=TRUE)
cat("  vs EPA/play:    ",sprintf("r=%+.3f",cor(tab$H_vs_lg,tab$epa_play,use="complete.obs")),"\n")
cat("  vs WPA/play:    ",sprintf("r=%+.3f",cor(tab$H_vs_lg,tab$wpa,use="complete.obs")),"\n")
cat("  vs success rate:",sprintf("r=%+.3f",cor(tab$H_vs_lg,tab$succ,use="complete.obs")),"\n")
cat("\nDONE\n")
