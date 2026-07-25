# =====================================================================
# THE GRIND - motion video (4:5 vertical, 30fps, ~50s)
# Renders frames with grid graphics, stitched to MP4 by ffmpeg.
#   Rscript scripts/motion_grind.R  &&  see motion/grind.mp4
# =====================================================================
suppressMessages(library(grid))

W <- 1080; H <- 1350; FPS <- 30
OUT <- "/Users/nick/stranger9977/nfl-analysis/motion"
FR  <- file.path(OUT, "frames_grind")
dir.create(OUT, showWarnings = FALSE); unlink(FR, recursive = TRUE); dir.create(FR)

# ---- palette + type (matches the Grind artifact) --------------------
bone <- "#e7e3d9"; ink <- "#1c1a15"; rust <- "#b0431f"; iron <- "#4c534d"
gain <- "#2f6b46"; mid  <- "#575347"; card <- "#f3f0e9"; rule <- "#c9c3b5"
DISP <- "HelveticaNeue-CondensedBlack"
BODY <- "Avenir Next Condensed"
MONO <- "Menlo"

# ---- easing helpers -------------------------------------------------
cl  <- function(x) pmin(1, pmax(0, x))
eo  <- function(t) 1 - (1 - cl(t))^3                      # ease-out cubic
eio <- function(t) { t <- cl(t); ifelse(t < .5, 4*t^3, 1-(-2*t+2)^3/2) }
# local time within a scene, in seconds
lt  <- function(f, start) (f - start) / FPS
# fade in over `d` sec starting at `s` sec of the scene
fi  <- function(tt, s = 0, d = .5) eo((tt - s) / d)
# fade out at the tail of a scene
fo  <- function(tt, s, d = .4) 1 - eo((tt - s) / d)

txt <- function(x, y, label, family = BODY, face = 1, cex = 1, col = ink,
                alpha = 1, adj = c(0, .5), lh = 1.2) {
  if (alpha <= 0.001) return(invisible())
  grid.text(label, x = x, y = y, just = c(if (adj[1] == 0) "left" else if (adj[1] == 1) "right" else "centre",
                                          if (adj[2] == 0) "bottom" else if (adj[2] == 1) "top" else "centre"),
            gp = gpar(fontfamily = family, fontface = face, cex = cex, col = col,
                      alpha = cl(alpha), lineheight = lh))
}
rect2 <- function(x, y, w, h, fill, alpha = 1, just = c("left","centre")) {
  if (alpha <= 0.001 || w <= 0) return(invisible())
  grid.rect(x = x, y = y, width = w, height = h, just = just,
            gp = gpar(fill = fill, col = NA, alpha = cl(alpha)))
}
lin <- function(x0, y0, x1, y1, col = rule, lwd = 2, alpha = 1, lty = 1) {
  if (alpha <= 0.001) return(invisible())
  grid.lines(x = c(x0, x1), y = c(y0, y1),
             gp = gpar(col = col, lwd = lwd, alpha = cl(alpha), lty = lty))
}
# count-up number
num <- function(from, to, t) from + (to - from) * eo(t)
sgn <- function(v) sprintf("%+.2f", v)

# ---- scene timing (seconds) ----------------------------------------
sc <- list(
  title  = c(0.0,   3.5),
  claim  = c(3.5,   8.0),
  down   = c(8.0,  16.0),
  long   = c(16.0, 23.0),
  wear   = c(23.0, 31.0),
  rev    = c(31.0, 39.0),
  dec    = c(39.0, 46.0),
  verd   = c(46.0, 50.5)
)
TOTAL <- 50.5; NFRAMES <- round(TOTAL * FPS)

# ---- chrome: yard stripes, chapter label, progress ------------------
chrome <- function(f, chapter = NULL, chalpha = 1) {
  for (i in 1:5) lin(i/6, 0, i/6, 1, col = rule, lwd = 1, alpha = .5)
  if (!is.null(chapter)) {
    txt(.07, .955, chapter, MONO, 1, .85, mid, chalpha)
  }
  # progress bar
  p <- f / NFRAMES
  rect2(0, .006, 1, .004, rule, .8)
  rect2(0, .006, p, .004, rust, 1)
}

# =====================================================================
# SCENE 1 - title
# =====================================================================
s_title <- function(tt) {
  a1 <- fi(tt, .15, .55); a2 <- fi(tt, .5, .55); a3 <- fi(tt, 1.05, .6)
  out <- fo(tt, 3.1, .4)
  y0 <- .60
  txt(.07, .78, "AGAINST THE BOOK   ·   PART 1 OF 4", MONO, 2, .95, rust, a1 * out)
  # THE / GRIND with slide-up
  sl <- (1 - eo(cl((tt - .35) / .7))) * .05
  txt(.07, y0 + .105 - sl, "THE", DISP, 1, 5.6, iron, a2 * out)
  txt(.07, y0 - .055 - sl, "GRIND", DISP, 1, 8.2, ink, a2 * out)
  lin(.07, y0 - .145, .07 + .58 * eo(cl((tt - 1.0) / .8)), y0 - .145, rust, 7, a3 * out)
  txt(.07, .375, "Establish the run and the pass opens up.", BODY, 1, 1.9, ink, a3 * out)
  txt(.07, .335, "The oldest article of faith in football.", BODY, 1, 1.9, mid, a3 * out)
  txt(.07, .255, "TESTED FIVE WAYS", MONO, 2, 1.05, rust, fi(tt, 1.7, .5) * out)
}

# =====================================================================
# SCENE 2 - the claim
# =====================================================================
s_claim <- function(tt) {
  a <- fi(tt, .1, .6); out <- fo(tt, 4.0, .4)
  lin(.09, .70, .09, .40, rust, 9, a * out)
  ls <- c('"You wear them down.', 'Establish the run,', 'impose your will,', 'and by the fourth quarter,',
          'by December,', 'they break."')
  for (i in seq_along(ls)) {
    ai <- fi(tt, .25 + i * .13, .5) * out
    txt(.14, .715 - (i - 1) * .058, ls[i], BODY, 3, 2.3, ink, ai)
  }
  txt(.14, .325, "EVERY RUN-FIRST COACH, SOME VERSION OF IT", MONO, 1, .95, mid, fi(tt, 1.5, .6) * out)
}

# =====================================================================
# SCENE 3 - test 1, the third-down setup
# =====================================================================
s_down <- function(tt) {
  a <- fi(tt, 0, .45); out <- fo(tt, 7.5, .45)
  txt(.07, .875, "TEST 1  ·  THE NEXT PLAY", MONO, 2, 1.0, rust, a * out)
  txt(.07, .80, "Run, run, then throw", DISP, 1, 3.4, ink, fi(tt, .15, .5) * out)
  txt(.07, .735, "Third-down pass, by what the offense did on 1st & 2nd", BODY, 1, 1.55, mid, fi(tt, .3, .5) * out)
  txt(.07, .700, "3rd & 3 to 7, the distances that decide drives", BODY, 1, 1.55, mid, fi(tt, .3, .5) * out)

  zx <- .50; scale <- 2.9   # x-position of zero, and units->npc
  lin(zx, .36, zx, .615, rule, 2, fi(tt, .5, .4) * out)
  txt(zx, .645, "0", MONO, 1, .95, mid, fi(tt, .5, .4) * out, adj = c(.5, .5))

  # row 1: passed twice -> +0.03
  t1 <- cl((tt - 1.0) / 1.5); a1 <- fi(tt, .8, .4) * out
  v1 <- num(0, .03, t1)
  txt(.07, .565, "PASSED on 1st & 2nd", BODY, 2, 1.6, ink, a1)
  rect2(zx, .515, max(0, v1) * scale, .046, gain, a1)
  txt(zx + max(0, v1) * scale + .015, .538, sgn(v1), DISP, 1, 2.1, gain, a1, adj = c(0, .5))

  # row 2: ran twice -> -0.04
  t2 <- cl((tt - 2.3) / 1.5); a2 <- fi(tt, 1.8, .4) * out
  v2 <- num(0, -.04, t2)
  txt(.07, .445, "RAN on 1st & 2nd", BODY, 2, 1.6, ink, a2)
  rect2(zx + v2 * scale, .395, abs(v2) * scale, .046, rust, a2)
  txt(zx + v2 * scale - .015, .418, sgn(v2), DISP, 1, 2.1, rust, a2, adj = c(1, .5))

  # payoff
  a3 <- fi(tt, 4.6, .6) * out
  lin(.07, .335, .93, .335, rule, 2, a3)
  txt(.07, .265, "Grinding it first makes the", BODY, 1, 2.05, ink, a3)
  txt(.07, .215, "third-down throw WORSE.", DISP, 1, 2.6, rust, fi(tt, 5.1, .5) * out)
  txt(.07, .145, "EXPECTED POINTS PER PLAY  ·  2015-2025  ·  n = 666-2,549", MONO, 1, .82, mid, fi(tt, 5.6, .5) * out)
}

# =====================================================================
# SCENE 4 - test 2, the long game (dots collapse to zero)
# =====================================================================
s_long <- function(tt) {
  out <- fo(tt, 6.5, .45)
  txt(.07, .875, "TEST 2  ·  THE LONG GAME", MONO, 2, 1.0, rust, fi(tt, 0, .45) * out)
  txt(.07, .80, "Pound it early, throw it late", DISP, 1, 3.0, ink, fi(tt, .15, .5) * out)
  txt(.07, .735, "Does first-half running predict later passing?", BODY, 1, 1.55, mid, fi(tt, .3, .5) * out)

  zx <- .62; scale <- .85
  # "no effect" band
  ab <- fi(tt, .55, .5) * out
  rect2(zx - .05 * scale, .28, .10 * scale, .33, "#b9d2c4", ab * .55, just = c("left","bottom"))
  txt(zx, .625, "NO EFFECT", MONO, 2, .82, gain, ab, adj = c(.5, .5))
  lin(zx, .28, zx, .61, rule, 2, ab)

  rows <- list(c("Later in the same half", -0.03), c("The second half", -0.05),
               c("The fourth quarter", -0.05), c("Play-action, 2nd half", -0.02))
  for (i in seq_along(rows)) {
    y  <- .565 - (i - 1) * .075
    ai <- fi(tt, .8 + i * .30, .45) * out
    tv <- cl((tt - (.85 + i * .30)) / 1.2)
    # slides in from where the myth would put it (+0.30) to reality
    v  <- 0.30 + (as.numeric(rows[[i]][2]) - 0.30) * eio(tv)
    txt(.07, y, rows[[i]][1], BODY, 1, 1.5, ink, ai)
    grid.circle(x = zx + v * scale, y = y, r = .0135,
                gp = gpar(fill = rust, col = NA, alpha = cl(ai)))
    txt(zx + v * scale, y + .032, sprintf("%+.2f", v), MONO, 2, .95, rust, ai, adj = c(.5, .5))
  }
  a4 <- fi(tt, 3.9, .6) * out
  lin(.07, .225, .93, .225, rule, 2, a4)
  txt(.07, .155, "Every horizon. Nothing.", DISP, 1, 2.6, rust, a4)
  txt(.07, .095, "Neutral game states only, so a lead isn't doing the work", MONO, 1, .82, mid, fi(tt, 4.4, .5) * out)
}

# =====================================================================
# SCENE 5 - test 3, the wear-down
# =====================================================================
s_wear <- function(tt) {
  out <- fo(tt, 7.0, .45)
  txt(.07, .875, "TEST 3  ·  THE WEAR-DOWN", MONO, 2, 1.0, rust, fi(tt, 0, .45) * out)
  txt(.07, .80, "The break doesn't show", DISP, 1, 3.0, ink, fi(tt, .15, .5) * out)
  txt(.07, .735, "Run success rate by quarter, neutral game states", BODY, 1, 1.55, mid, fi(tt, .3, .5) * out)

  x0 <- .12; x1 <- .90; yb <- .33; yt <- .64
  vals <- c(.394, .405, .397, .401)          # Q1..Q4 success
  yv <- function(v) yb + (v - .36) / (.48 - .36) * (yt - yb)
  ax <- fi(tt, .45, .45) * out
  lin(x0, yb, x1, yb, rule, 2, ax)
  for (i in 1:4) txt(x0 + (i - 1) / 3 * (x1 - x0), yb - .035, paste0("Q", i), MONO, 2, 1.0, mid, ax, adj = c(.5, .5))
  txt(x0 - .02, yv(.40), "40%", MONO, 1, .85, mid, ax, adj = c(1, .5))

  # ghost: what wearing down would look like
  ag <- fi(tt, .8, .5) * out
  pg <- cl((tt - 1.0) / 1.4)
  gx <- x0 + (x1 - x0) * pg
  lin(x0, yv(.394), gx, yv(.394 + (.455 - .394) * pg), iron, 3, ag * .55, lty = 2)
  txt(x1, yv(.462), "if defenses wore down", MONO, 1, .88, iron, fi(tt, 1.6, .5) * out * .8, adj = c(1, .5))

  # actual: flat line drawing across
  pa <- cl((tt - 1.9) / 1.8); aa <- fi(tt, 1.9, .3) * out
  seg <- pa * 3
  for (i in 1:3) {
    fseg <- cl(seg - (i - 1))
    if (fseg > 0) lin(x0 + (i-1)/3*(x1-x0), yv(vals[i]),
                      x0 + ((i-1) + fseg)/3*(x1-x0), yv(vals[i] + (vals[i+1]-vals[i])*fseg), rust, 7, aa)
  }
  for (i in 1:4) {
    if (seg >= i - 1) grid.circle(x = x0 + (i-1)/3*(x1-x0), y = yv(vals[i]), r = .012,
                                  gp = gpar(fill = rust, col = NA, alpha = cl(aa)))
  }
  a3 <- fi(tt, 3.6, .55) * out
  lin(.07, .285, .93, .285, rule, 2, a3)
  txt(.07, .215, "+0.00", DISP, 1, 3.6, rust, a3)
  txt(.07, .145, "early carries vs 4th-quarter running", BODY, 1, 1.6, ink, fi(tt, 4.1, .5) * out)
  a4 <- fi(tt, 4.8, .55) * out
  txt(.07, .092, "Attrition may well be real. Modern lines rotate,", MONO, 1, .82, mid, a4)
  txt(.07, .060, "and whatever it does never reaches the box score.", MONO, 1, .82, mid, a4)
}

# =====================================================================
# SCENE 6 - test 4, the reverse
# =====================================================================
s_rev <- function(tt) {
  out <- fo(tt, 7.5, .45)
  txt(.07, .885, "TEST 4  ·  THE REVERSE", MONO, 2, 1.0, rust, fi(tt, 0, .45) * out)
  txt(.07, .815, "The pass sets up the run", DISP, 1, 3.0, ink, fi(tt, .15, .5) * out)
  txt(.07, .750, "Early-down run success, by defenders in the box", BODY, 1, 1.55, mid, fi(tt, .3, .5) * out)

  rows <- list(list("LIGHT box  (6 or fewer)", .39, gain),
               list("EVEN box  (7)",           .37, iron),
               list("STACKED box  (8+)",       .35, rust))
  bx <- .07; bw <- .70
  for (i in seq_along(rows)) {
    y  <- .655 - (i - 1) * .095
    ai <- fi(tt, .55 + i * .36, .45) * out
    tv <- cl((tt - (.6 + i * .36)) / 1.2)
    v  <- num(0, rows[[i]][[2]], tv)
    txt(bx, y + .036, rows[[i]][[1]], BODY, 2, 1.5, ink, ai)
    rect2(bx, y - .019, bw * (v / .45), .038, rows[[i]][[3]], ai)
    txt(bx + bw * (v / .45) + .015, y, sprintf("%.0f%%", v * 100), DISP, 1, 2.0, rows[[i]][[3]], ai, adj = c(0, .5))
  }
  # the flip
  a4 <- fi(tt, 3.3, .55) * out
  lin(.07, .345, .93, .345, rule, 2, a4)
  txt(.07, .275, sprintf("%.2f", num(0, -0.51, cl((tt - 3.4) / 1.4))), DISP, 1, 3.8, rust, a4)
  txt(.07, .205, "pass rate vs the box you face", BODY, 1, 1.6, ink, fi(tt, 5.4, .5) * out)
  a5 <- fi(tt, 4.9, .55) * out
  txt(.07, .135, "You don't run to set up the pass.", BODY, 1, 1.9, mid, a5)
  txt(.07, .085, "You PASS to open up the run.", DISP, 1, 2.5, ink, fi(tt, 5.4, .5) * out)
}

# =====================================================================
# SCENE 7 - December, the grain of truth
# =====================================================================
s_dec <- function(tt) {
  out <- fo(tt, 6.5, .45)
  txt(.07, .885, "THE GRAIN OF TRUTH", MONO, 2, 1.0, rust, fi(tt, 0, .45) * out)
  txt(.07, .815, "December football", DISP, 1, 3.4, ink, fi(tt, .15, .5) * out)
  txt(.07, .750, "How much better passing is than running, by temperature", BODY, 1, 1.5, mid, fi(tt, .3, .5) * out)

  x0 <- .13; x1 <- .90; yb <- .36; yt <- .655
  vals <- c(.15, .12, .09, .04); labs <- c("70F+", "46-55", "26-35", "<25F")
  yv <- function(v) yb + (v / .18) * (yt - yb)
  ax <- fi(tt, .45, .45) * out
  lin(x0, yb, x1, yb, ink, 3, ax)                                  # zero line
  txt(x0, yb - .035, "0  ·  running is the better call below this line", MONO, 1, .84, mid, ax)
  for (i in 1:4) txt(x0 + (i - 1)/3 * (x1 - x0), yt + .045, labs[i], MONO, 2, .95, mid, ax, adj = c(.5, .5))

  pa <- cl((tt - 1.0) / 2.0); aa <- fi(tt, .85, .35) * out
  seg <- pa * 3
  for (i in 1:3) {
    fs <- cl(seg - (i - 1))
    if (fs > 0) lin(x0 + (i-1)/3*(x1-x0), yv(vals[i]),
                    x0 + ((i-1)+fs)/3*(x1-x0), yv(vals[i] + (vals[i+1]-vals[i])*fs), rust, 7, aa)
  }
  for (i in 1:4) if (seg >= i - 1) {
    grid.circle(x = x0 + (i-1)/3*(x1-x0), y = yv(vals[i]), r = .012, gp = gpar(fill = rust, col = NA, alpha = cl(aa)))
    txt(x0 + (i-1)/3*(x1-x0), yv(vals[i]) + .042, sprintf("+%.2f", vals[i]), MONO, 2, .95, rust, aa, adj = c(.5, .5))
  }
  a3 <- fi(tt, 3.6, .55) * out
  lin(.07, .295, .93, .295, rule, 2, a3)
  txt(.07, .225, "The edge nearly vanishes.", BODY, 1, 1.95, ink, a3)
  txt(.07, .160, "It never flips.", DISP, 1, 3.0, rust, fi(tt, 4.1, .5) * out)
  txt(.07, .092, "Throwing stays the better bet even on a frozen field", MONO, 1, .84, mid, fi(tt, 4.6, .5) * out)
}

# =====================================================================
# SCENE 8 - verdict
# =====================================================================
s_verd <- function(tt) {
  a <- fi(tt, 0, .5)
  txt(.07, .855, "THE VERDICT", MONO, 2, 1.05, rust, a)
  ls <- list(c("The run does not set up the pass.", ink),
             c("The wear-down never shows up.", ink),
             c("Passing is what opens the run.", rust))
  for (i in seq_along(ls)) {
    txt(.07, .745 - (i - 1) * .085, ls[[i]][1], DISP, 1, 2.7, ls[[i]][2], fi(tt, .35 + i * .38, .5))
  }
  a2 <- fi(tt, 2.3, .6)
  lin(.07, .445, .93, .445, rule, 2, a2)
  txt(.07, .375, "The one thing the grinders get right", BODY, 1, 1.8, mid, a2)
  txt(.07, .325, "is the weather.", BODY, 1, 1.8, mid, a2)
  a3 <- fi(tt, 3.0, .6)
  txt(.07, .205, "AGAINST THE BOOK", DISP, 1, 2.4, ink, a3)
  txt(.07, .150, "PART 1 OF 4  ·  nflverse play-by-play, 2015-2025", MONO, 1, .95, mid, a3)
}

# =====================================================================
# render
# =====================================================================
chap <- function(tt_name) switch(tt_name,
  title = NULL, claim = NULL, down = "THE GRIND", long = "THE GRIND",
  wear = "THE GRIND", rev = "THE GRIND", dec = "THE GRIND", verd = NULL)

cat("rendering", NFRAMES, "frames...\n")
for (f in 0:(NFRAMES - 1)) {
  s <- f / FPS
  png(file.path(FR, sprintf("f%05d.png", f)), width = W, height = H, res = 150, type = "quartz")
  grid.newpage()
  grid.rect(gp = gpar(fill = bone, col = NA))
  nm <- names(sc)[sapply(sc, function(r) s >= r[1] && s < r[2])][1]
  if (is.na(nm)) nm <- "verd"
  chrome(f, chap(nm), 1)
  tt <- s - sc[[nm]][1]
  switch(nm, title = s_title(tt), claim = s_claim(tt), down = s_down(tt), long = s_long(tt),
         wear = s_wear(tt), rev = s_rev(tt), dec = s_dec(tt), verd = s_verd(tt))
  dev.off()
  if (f %% 150 == 0) cat("  ", f, "/", NFRAMES, "\n")
}

cat("stitching...\n")
mp4 <- file.path(OUT, "grind.mp4")
system(sprintf(
  "ffmpeg -y -loglevel error -framerate %d -i %s/f%%05d.png -c:v libx264 -profile:v high -pix_fmt yuv420p -crf 18 -movflags +faststart %s",
  FPS, FR, mp4))
cat("DONE ->", mp4, "\n")
