# Flesh out "predictable": concrete tendency tells for the marquee callers,
# a refreshed fingerprint grid (Reid, McVay, Shanahan, LaFleur, Ben Johnson,
# Gase), and predictability-vs-offense in three metrics for a toggle.
suppressMessages({library(data.table); library(ggplot2); library(scales)})
setDTthreads(4)
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")
ROOT <- "/Users/nick/stranger9977/nfl-analysis"
p  <- as.data.table(readRDS(file.path(ROOT,"scratch/pred_plays.rds")))
cc <- as.data.table(readRDS(file.path(ROOT,"scratch/pred_career.rds")))
tab<- as.data.table(readRDS(file.path(ROOT,"scratch/pred_tab.rds")))
marquee <- c("Andy Reid","Sean McVay","Kyle Shanahan","Matt LaFleur","Ben Johnson","Adam Gase")

## ---------- concrete tells (printed for copy) ----------
p13 <- p[down %in% 1:3]
tell <- function(flt, name){
  lg <- p13[eval(flt), mean(is_pass)]
  x  <- p13[off_play_caller %in% marquee & eval(flt),
            .(pass=round(mean(is_pass),3), n=.N), by=off_play_caller]
  x[, league := round(lg,3)]; x[, situation := name]; x[]
}
cat("=== concrete pass-rate tells (marquee vs league) ===\n")
print(tell(quote(down==1 & ydstogo==10), "1st & 10"))
print(tell(quote(down==2 & ydstogo<=3),  "2nd & short (<=3)"))
print(tell(quote(down==2 & ydstogo>=8),  "2nd & long (8+)"))
print(tell(quote(down==1 & yardline_100<=10), "1st & goal-ish (inside 10)"))
cat("\n=== career guessability + EPA (marquee) ===\n")
print(cc[off_play_caller %in% marquee,
         .(off_play_caller, n_plays, guess_xs=round(guess_xs,2),
           H_vs_lg=round(H_vs_lg,3), epa=round(epa_play,3))][order(-guess_xs)])

## ---------- refreshed fingerprint grid ----------
p13[, togo_b := factor(togo_b, levels=c("1-3","4-6","7-10","11+"))]
lg <- p13[, .(lg=mean(is_pass)), by=.(down,togo_b)]; lg_overall <- p13[, mean(is_pass)]
K <- 15
cells <- p13[off_play_caller %in% marquee, .(np=sum(is_pass), n=.N), by=.(off_play_caller,down,togo_b)]
cells <- merge(cells, lg, by=c("down","togo_b"))
cells[, pr:=np/n]; cells[, p_shr:=(np+K*lg)/(n+K)]
cells[, contrib:=(pmax(p_shr,1-p_shr) - pmax(lg,1-lg))*100]
grid <- cells[, .(guess=sum(contrib*n)/sum(n)), by=off_play_caller]
ann <- merge(grid, cc[off_play_caller %in% marquee, .(off_play_caller, epa_play)], by="off_play_caller")
setorder(ann, -guess)
lab <- sapply(marquee, function(nm){a<-ann[off_play_caller==nm]
  sprintf("%s\nguessability %+.1f / 100   ·   EPA/play %+.3f", nm, a$guess, a$epa_play)})
names(lab) <- marquee
cells[, sub := n<25]; cells[sub==TRUE, contrib:=NA]
cells[, off_play_caller := factor(off_play_caller, levels=ann$off_play_caller, labels=lab[ann$off_play_caller])]
cells[, cell_lab := ifelse(sub, paste0("n=",n), paste0(round(pr*100),"%"))]
cells[, down_lab := factor(paste0(down, ifelse(down==1,"st",ifelse(down==2,"nd","rd"))),
                           levels=c("3rd","2nd","1st"))]
lim <- max(abs(cells$contrib), na.rm=TRUE)
r_g <- cor(cc$guess_xs, cc$epa_play)
p1 <- ggplot(cells, aes(togo_b, down_lab, fill=contrib)) +
  geom_tile(color=col_surface, linewidth=1.1) +
  geom_text(aes(label=cell_lab, color=abs(contrib)>0.62*lim | is.na(contrib)),
            size=3.0, fontface="bold") +
  scale_color_manual(values=c("TRUE"="#ffffff","FALSE"=ink_primary), guide="none", na.value=ink_muted) +
  facet_wrap(~off_play_caller, ncol=3) +
  scale_fill_gradient2(low=pal_div$low, mid=pal_div$mid, high=pal_div$high, midpoint=0,
                       limits=c(-lim,lim), na.value="#e6e5df",
                       labels=function(x) sprintf("%+d",round(x)),
                       name="Guessability vs league\n(extra correct run/pass\ncalls per 100, in cell)\n\nred = easier to guess\nblue = harder (coin-flip)") +
  labs(title="What predictable looks like: Andy Reid tips his hand, Ben Johnson doesn't, and both run elite offenses",
       subtitle="Each grid is a play-caller. Color shows how much easier (red) or harder (blue) than the league you are to guess at that down and distance;\nthe number is the caller's pass rate there. Reid, McVay and LaFleur run deep red and win. Ben Johnson stays near coin-flip blue and wins too.",
       x="Yards to go", y=NULL,
       caption=sprintf("Called plays, downs 1-3, 2015-2025 (caller-attributed). Guessability = an optimal situational guesser's hit-rate on the caller minus on the league, EB-shrunk (K=15). League pass rate %.0f%%.\nMore-predictable-than-league goes with slightly BETTER offense (r = %+.2f across callers), not worse. EPA reflects the QB and cast too, not the caller alone.", lg_overall*100, r_g)) +
  theme_nfl(base_size=12) +
  theme(panel.grid=element_blank(), axis.text=element_text(color=ink_secondary,size=10),
        strip.text=element_text(face="bold",size=9.2,color=ink_primary,lineheight=1.08,margin=margin(4,2,4,2)),
        legend.position="right", legend.key.height=unit(24,"pt"),
        legend.title=element_text(size=9,lineheight=1.0),
        plot.subtitle=element_text(lineheight=1.12), panel.spacing=unit(14,"pt"))
save_chart(p1, "tendency-fingerprints", width=14, height=8.9)

## ---------- predictability vs offense in 3 metrics (toggle) ----------
tq <- as.data.table(readRDS(file.path(ROOT,"data/pbp_slim.rds")))[, .(game_id,play_id,wpa,success)]
pj <- merge(p[, .(game_id,play_id,off_play_caller)], tq, by=c("game_id","play_id"), all.x=TRUE)
car_m <- pj[, .(wpa=mean(wpa,na.rm=TRUE), succ=mean(success,na.rm=TRUE)), by=off_play_caller]
C <- merge(cc[, .(off_play_caller, n_plays, guess_xs, epa_play)], car_m, by="off_play_caller")
setnames(C, "epa_play", "epa")
lab_pts <- c("Andy Reid","Sean McVay","Kyle Shanahan","Matt LaFleur","Ben Johnson","Adam Gase","Kliff Kingsbury","Joe Brady")
METR <- list(epa=list(col="epa", nm="EPA per play", file="epa", fmt=function(x) number(x,.01,style_positive="plus")),
             success=list(col="succ", nm="success rate", file="success", fmt=function(x) percent(x,1)),
             wpa=list(col="wpa", nm="win probability added", file="wpa", fmt=function(x) number(x,.001,style_positive="plus")))
for (mk in names(METR)){
  m <- METR[[mk]]; C[, yv := get(m$col)]; r <- cor(C$guess_xs, C$yv)
  C[, foc := off_play_caller %in% lab_pts]
  g <- ggplot(C, aes(guess_xs, yv)) +
    geom_hline(yintercept=mean(C$yv), color=col_grid, linewidth=.3) +
    geom_smooth(method="lm", se=TRUE, color=pal_cat[1], fill=pal_cat[1], alpha=.10, linewidth=.9) +
    geom_point(data=C[foc==FALSE], color=col_baseline, size=2, alpha=.7) +
    geom_point(data=C[foc==TRUE], color=pal_cat[1], size=3.1) +
    ggrepel::geom_text_repel(data=C[foc==TRUE], aes(label=off_play_caller),
        size=3.2, color=ink_primary, fontface="bold", seed=7, min.segment.length=0, box.padding=.5) +
    annotate("text", x=min(C$guess_xs), y=max(C$yv),
             label=sprintf("r = %+.2f", r), hjust=0, vjust=1, size=4.2, fontface="bold",
             color=ink_primary, family="sans") +
    annotate("text", x=max(C$guess_xs), y=min(C$yv), label="more predictable ->", hjust=1, vjust=0,
             size=3, color=ink_muted, family="mono") +
    scale_y_continuous(labels=m$fmt) +
    labs(title=sprintf("More predictable play-callers run better offenses (%s)", m$nm),
         subtitle="Each dot is a career play-caller (2015-2025, 1,000+ plays). Right = more predictable than the league in the same\nsituations. The prolific names sit on the right and up; Ben Johnson is the rare elite who stays hard to read.",
         x="Predictability (extra plays out of 100 an optimal guesser calls right, vs league)",
         y=sprintf("Offense (%s)", m$nm),
         caption="nflverse play-by-play, 2015-2025, caller-attributed. Situation-controlled predictability, empirical-Bayes de-biased.\nLink holds in all three metrics (here r = +0.35 to +0.44; equivalently -0.37 to -0.40 on the entropy scale, across 377 caller-seasons).") +
    theme_nfl()
  save_chart(g, paste0("predictability-offense-", m$file), width=10, height=6.2)
  cat(mk, "career r(guess_xs, ", m$col, ") =", round(r,3), "\n")
}
cat("\nDONE\n")
