# =====================================================================
# IS IT THE CALLER OR THE QB?
# (1) Predictability is a STABLE caller trait: H_vs_lg autocorrelates
#     r=0.48 across consecutive caller-seasons (r=0.34 even across a QB
#     change) -> it travels with the coach, not the quarterback.
# (2) The predictability->offense link SURVIVES removing QB talent:
#     raw r(H_vs_lg,EPA)=-0.371 -> partial r | QB cpoe = -0.256
#     (standardized beta -0.20, p<.001). QB completion-over-expected is
#     the bigger driver (beta +0.60) but does NOT explain it away.
# Universe: caller-seasons >=300 called plays, 2015-2025.
# =====================================================================
suppressMessages({library(data.table); library(ggplot2); library(patchwork)})
source("/Users/nick/stranger9977/nfl-analysis/scripts/theme_nfl.R")
SC <- "/private/tmp/claude-501/-Users-nick-stranger9977/fa82bd70-8c03-4970-9197-8f31c9f58176/scratchpad"
st  <- as.data.table(readRDS(file.path(SC,"stability.rds")))
tab <- as.data.table(readRDS(file.path(SC,"tab_qb.rds")))

# ---------- numbers ----------
fz <- function(r,n){z<-atanh(r); se<-1/sqrt(n-3); tanh(z+c(-1.96,1.96)*se)}  # Fisher-z 95% CI
r_auto  <- cor(st$H_vs_lg, st$H_next)                       # 0.477
r_same  <- cor(st[qb_changed==FALSE]$H_vs_lg, st[qb_changed==FALSE]$H_next); n_same <- st[qb_changed==FALSE,.N] # 0.543 / 125
r_qbchg <- cor(st[qb_changed==TRUE]$H_vs_lg,  st[qb_changed==TRUE]$H_next);  n_chg  <- st[qb_changed==TRUE,.N]  # 0.338 / 103
ci_same <- fz(r_same, n_same)                               # [0.41, 0.66]
ci_chg  <- fz(r_qbchg, n_chg)                               # [0.16, 0.50]
# Is the same-QB vs QB-change gap distinguishable? Independent Fisher-z test:
z_diff <- (atanh(r_same)-atanh(r_qbchg))/sqrt(1/(n_same-3)+1/(n_chg-3))
p_diff <- 2*(1-pnorm(abs(z_diff)))                          # z=1.90, p=0.058 -> NOT distinguishable
r_raw   <- cor(tab$H_vs_lg, tab$epa_play)                   # -0.371
pcor <- function(x,y,z){rxy<-cor(x,y);rxz<-cor(x,z);ryz<-cor(y,z);(rxy-rxz*ryz)/sqrt((1-rxz^2)*(1-ryz^2))}
r_part  <- pcor(tab$H_vs_lg, tab$epa_play, tab$qb_cpoe)     # -0.256 (cpoe proxy, preferred)
r_part_e<- pcor(tab$H_vs_lg, tab$epa_play, tab$qb_epa)      # -0.092 (qb_epa proxy, over-controls)

# ================= PANEL 1: stability scatter =================
ex <- c("Andy Reid","Ben Johnson","Kyle Shanahan","Sean McVay","Kliff Kingsbury")
st[, hl := off_play_caller %in% ex]
lab <- st[hl==TRUE, .(x=mean(H_vs_lg), y=mean(H_next)), by=off_play_caller]
lab[, nm := c("Andy Reid"="Andy Reid  (predictable elite, n=9)",
              "Ben Johnson"="Ben Johnson  (n=3 pairs)",
              "Kyle Shanahan"="Kyle Shanahan","Sean McVay"="Sean McVay",
              "Kliff Kingsbury"="Kliff Kingsbury")[off_play_caller]]
rng <- range(c(st$H_vs_lg, st$H_next))
# per-label nudges so Ben Johnson (top-right dots) clears the top-left stat block
lab[, `:=`(nx=0, ny=0)]
lab[off_play_caller=="Ben Johnson", `:=`(nx=0.004, ny=-0.012)]
lab[off_play_caller=="Andy Reid",   `:=`(nx=-0.004, ny=0.002)]
col_reid <- pal_cat[1]; col_bj <- pal_cat[2]
st[, cgrp := ifelse(off_play_caller=="Andy Reid","reid",
             ifelse(off_play_caller=="Ben Johnson","bj",
             ifelse(hl,"other_hl","rest")))]

p1 <- ggplot(st, aes(H_vs_lg, H_next)) +
  annotate("segment", x=0, xend=0, y=rng[1], yend=rng[2], color=col_baseline, linewidth=.3, linetype="22") +
  annotate("segment", x=rng[1], xend=rng[2], y=0, yend=0, color=col_baseline, linewidth=.3, linetype="22") +
  geom_abline(slope=1, intercept=0, color=ink_muted, linewidth=.35, linetype="42") +
  geom_point(data=st[cgrp=="rest"], color=col_baseline, size=1.9, alpha=.8) +
  geom_smooth(method="lm", se=FALSE, color=ink_secondary, linewidth=.8) +
  geom_point(data=st[cgrp=="other_hl"], color=ink_secondary, size=2.4) +
  geom_point(data=st[cgrp=="reid"], color=col_reid, size=2.8) +
  geom_point(data=st[cgrp=="bj"], color=col_bj, size=2.8) +
  ggrepel::geom_text_repel(data=lab, aes(x,y,label=nm),
      size=3.2, color=ink_primary, fontface="bold", segment.color=ink_muted,
      nudge_x=lab$nx, nudge_y=lab$ny,
      min.segment.length=0, box.padding=.7, point.padding=.4, max.overlaps=Inf) +
  annotate("text", x=rng[1]+.001, y=rng[2]-.001, hjust=0, vjust=1,
      label=sprintf("Predictability persists season to season\nsame QB:  r = %.2f  [%.2f, %.2f]\nafter a QB change:  r = %.2f  [%.2f, %.2f]",
                    r_same, ci_same[1], ci_same[2], r_qbchg, ci_chg[1], ci_chg[2]),
      size=3.6, fontface="bold", color=ink_primary) +
  annotate("text", x=rng[1]+.001, y=rng[2]-.0135, hjust=0, vjust=1,
      label=sprintf("95%% CIs overlap: gap not distinguishable (p=%.2f)", p_diff),
      size=2.7, color=ink_muted) +
  annotate("text", x=rng[1]+.001, y=rng[1]+.001, hjust=0, vjust=0,
      label="lower-left = predictable in both years    (bold label = coach's multi-season average)",
      size=2.7, color=ink_muted) +
  scale_x_continuous(labels=scales::number_format(accuracy=.01)) +
  scale_y_continuous(labels=scales::number_format(accuracy=.01)) +
  coord_equal(xlim=rng, ylim=rng) +
  labs(subtitle="Trait stability. Each dot is one coach in back-to-back seasons",
       x="Predictability this season  (entropy vs league, bits)",
       y="Predictability next season") +
  theme_nfl()

# ================= PANEL 2: survives QB control =================
# Third bar discloses the qb_EPA proxy sensitivity: the partial falls to -0.09,
# but qb_EPA over-controls (dropback EPA embeds the caller's own play design),
# so cpoe is the preferred proxy. Show both -> honest robustness range.
bars <- data.table(
  lab = c("Raw\ncorrelation","Remove QB\naccuracy (cpoe)","Remove QB\ntotal EPA*"),
  r   = c(r_raw, r_part, r_part_e),
  grp = c("raw","cpoe","epa"))
bars[, lab := factor(lab, levels=lab)]
p2 <- ggplot(bars, aes(lab, r, fill=grp)) +
  geom_hline(yintercept=0, color=ink_secondary, linewidth=.4) +
  geom_col(width=.66) +
  geom_text(aes(y=r-0.016, label=sprintf("%.2f", r)), color=ink_primary, fontface="bold", size=5) +
  annotate("text", x=2.5, y=0.028, label="range across QB proxies", size=2.9,
      color=ink_secondary, fontface="bold", vjust=0.5) +
  annotate("segment", x=2, xend=3, y=0.012, yend=0.012, color=ink_muted, linewidth=.3) +
  annotate("segment", x=2, xend=2, y=0.012, yend=-0.003, color=ink_muted, linewidth=.3) +
  annotate("segment", x=3, xend=3, y=0.012, yend=-0.003, color=ink_muted, linewidth=.3) +
  annotate("text", x=2, y=-0.415,
      label="The link shrinks but stays negative under\neither QB control (-0.26 to -0.09)", size=3.0,
      color=ink_secondary, fontface="bold", vjust=0.5) +
  annotate("text", x=3, y=-0.44, label="*over-controls", size=2.5, color=ink_muted, vjust=0.5) +
  scale_fill_manual(values=c(raw=col_baseline, cpoe=pal_cat[1], epa=pal_seq[2]), guide="none") +
  scale_y_continuous(limits=c(-0.46,0.05), breaks=seq(-0.4,0,.1)) +
  labs(subtitle="Predictability → offense (EPA/play),\nbefore vs after controlling for the QB",
       x=NULL, y="correlation with offensive EPA/play") +
  theme_nfl() +
  theme(axis.text.x=element_text(size=9, color=ink_secondary, face="bold"))

# ================= assemble =================
fig <- (p1 | p2) + plot_layout(widths=c(1.65,1)) +
  plot_annotation(
    title="Predictable play-calling is a stable coaching trait that still predicts offense after you remove the QB",
    subtitle="Left: a coach's situation-controlled predictability in one season forecasts the next, and stays positive even across a QB change (CIs overlap, so the same-QB vs QB-change gap is not distinguishable).\nRight: the predictability-offense link shrinks but stays negative under either QB control (-0.26 to -0.09).",
    caption=paste0(
      "Caller-attributed called plays, 2015-2025 (nflverse). Universe: caller-seasons with >=300 plays (n=377; 228 consecutive pairs, 125 same QB, 103 across a QB change). Predictability = within-situation run/pass\n",
      "entropy minus league entropy in the same situation cells (empirical-Bayes shrunk, K=15); negative = more predictable. QB quality = mean completion-over-expected (cpoe) on caller's dropbacks. Stability CIs are Fisher-z 95%.\n",
      "Standardized OLS EPA ~ predictability + QB cpoe: beta = -0.20 (p<.001) and +0.60. Partial r(predictability, EPA | cpoe) = -0.26 vs raw -0.37. *Under a fuller (but over-controlling) qb_EPA proxy the partial falls to -0.09;\n",
      "cpoe is preferred because dropback EPA embeds the caller's own play-design value. Observational - controlling reduces but cannot eliminate confounding."),
    theme=theme_nfl() + theme(plot.title=element_text(size=15.5), plot.subtitle=element_text(size=10.3)))

save_chart(fig, "caller-vs-qb", width=15, height=7.4)
cat(sprintf("r_same=%.3f [%.3f,%.3f] n=%d | r_qbchg=%.3f [%.3f,%.3f] n=%d | gap p=%.3f\n",
            r_same,ci_same[1],ci_same[2],n_same, r_qbchg,ci_chg[1],ci_chg[2],n_chg, p_diff))
cat(sprintf("r_raw=%.3f | r_part|cpoe=%.3f | r_part|qb_epa=%.3f\n", r_raw, r_part, r_part_e))
