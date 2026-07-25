# =====================================================================
# THE GRIND - motion video (4:5 vertical, 30fps, ~100s)
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
  title  = c(0.0,    5.0),
  claim  = c(5.0,   12.0),
  quotes = c(12.0,  25.0),
  down   = c(25.0,  38.0),
  long   = c(38.0,  50.0),
  wear   = c(50.0,  63.0),
  rev    = c(63.0,  80.0),
  dec    = c(80.0,  92.0),
  verd   = c(92.0, 100.0)
)
TOTAL <- 100.0; NFRAMES <- round(TOTAL * FPS)

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
  a1 <- fi(tt, 0.214, 0.632); a2 <- fi(tt, 0.715, 0.632); a3 <- fi(tt, 1.502, 0.69)
  out <- fo(tt, 4.4, .4)
  y0 <- .60
  txt(.07, .78, "EVERY NFL PLAY  ·  2015 TO 2025", MONO, 2, .95, rust, a1 * out)
  # THE / GRIND with slide-up
  sl <- (1 - eo(cl((tt - 0.5) / 0.805))) * .05
  txt(.07, y0 + .105 - sl, "THE", DISP, 1, 5.6, iron, a2 * out)
  txt(.07, y0 - .055 - sl, "GRIND", DISP, 1, 8.2, ink, a2 * out)
  lin(.07, y0 - .145, .07 + .58 * eo(cl((tt - 1.43) / 0.92)), y0 - .145, rust, 7, a3 * out)
  txt(.07, .375, "Establish the run and the pass opens up.", BODY, 1, 1.9, ink, a3 * out)
  txt(.07, .335, "The oldest article of faith in football.", BODY, 1, 1.9, mid, a3 * out)
  txt(.07, .255, "TESTED FIVE WAYS", MONO, 2, 1.05, rust, fi(tt, 2.431, 0.575) * out)
}

# =====================================================================
# SCENE 2 - the claim
# =====================================================================
s_claim <- function(tt) {
  a <- fi(tt, 0.155, 0.69); out <- fo(tt, 6.4, .4)
  lin(.09, .70, .09, .40, rust, 9, a * out)
  ls <- c('"You wear them down.', 'Establish the run,', 'impose your will,', 'and by the fourth quarter,',
          'by December,', 'they break."')
  for (i in seq_along(ls)) {
    ai <- fi(tt, 0.388 + i * 0.202, 0.575) * out
    txt(.14, .715 - (i - 1) * .058, ls[i], BODY, 3, 2.3, ink, ai)
  }
  txt(.14, .325, "EVERY RUN-FIRST COACH, SOME VERSION OF IT", MONO, 1, .95, mid, fi(tt, 2.325, 0.69) * out)
}

# =====================================================================
# SCENE 2b - the quote wall. Real, sourced quotes, flooding the screen.
# Every line here is verbatim (… marks omitted words); see QUOTES.md.
# =====================================================================
QW <- list(
  list(.06, .900, 1.12, 0, "\"Running the football, it's our identity.\"",            "JOHN HARBAUGH  ·  RAVENS  ·  2016",   ink),
  list(.94, .853, 0.92, 1, "\"You gotta run that football.\"",                        "DAN ROONEY  ·  STEELERS OWNER",       iron),
  list(.06, .806, 0.84, 0, "\"Any team that can run the football has an advantage.\"", "GREG ROMAN  ·  RAVENS OC  ·  2021",  iron),
  list(.94, .757, 1.28, 1, "\"I want to run the damn ball…\"",                        "MIKE McCARTHY  ·  COWBOYS  ·  2023",  rust),
  list(.06, .708, 0.86, 0, "\"…we're gonna run to win.\"",                            "SHANE STEICHEN  ·  COLTS  ·  2023",   ink),
  list(.94, .659, 1.02, 1, "\"Our identity will be physical.\"",                      "KIRBY SMART  ·  GEORGIA  ·  2026",    iron),
  list(.06, .610, 1.16, 0, "\"…you're darn right we are.\"",                          "REX RYAN  ·  BILLS  ·  2015",         rust),
  list(.94, .561, 0.84, 1, "\"You got to be able to establish the run…\"",            "NICK SABAN  ·  2025",                 ink),
  list(.06, .512, 0.82, 0, "\"…control the line of scrimmage.\"",                     "BRIAN DABOLL  ·  GIANTS  ·  2025",    iron),
  list(.94, .463, 1.00, 1, "\"…run it more.\"",                                       "PETE CARROLL  ·  SEAHAWKS  ·  2021",  ink),
  list(.06, .414, 0.82, 0, "\"…nine times out of 10, they will break.\"",             "ROQUAN SMITH  ·  RAVENS  ·  2024",    iron),
  list(.94, .365, 1.10, 1, "\"We're a running team…\"",                               "JOHN HARBAUGH  ·  RAVENS  ·  2025",   rust),
  list(.06, .316, 0.84, 0, "\"I'm looking for that physical, tough running presence.\"","RON RIVERA  ·  PANTHERS  ·  2017",  ink),
  list(.94, .267, 0.86, 1, "\"…three yards and a cloud of dust.\"",                    "WOODY HAYES  ·  OHIO STATE  ·  1959", iron),
  list(.06, .218, 0.82, 0, "\"…hang our hat on, running the ball…\"",                  "DeMECO RYANS  ·  TEXANS  ·  2023",    ink),
  list(.94, .169, 0.84, 1, "\"…it takes a whole defense to stop it…\"",                "MIKE SHANAHAN  ·  BRONCOS",           iron),
  list(.06, .120, 0.86, 0, "\"Because it's the best way to not screw it up.\"",        "PETE CARROLL  ·  SEAHAWKS  ·  2018",  ink),
  list(.94, .071, 0.82, 1, "\"…physically run the ball and control the game.\"",       "KYLE SHANAHAN  ·  49ERS  ·  2025",    iron)
)
s_quotes <- function(tt) {
  out <- fo(tt, 12.4, .5)
  HOLD <- 1.15   # seconds each quote stays highlighted before receding
  for (i in seq_along(QW)) {
    q  <- QW[[i]]
    st <- 0.25 + (i - 1) * 0.45 - (i - 1)^2 * 0.0093   # accelerating cadence
    ap <- fi(tt, st, .34)                              # arrive
    if (ap <= .001) next
    # highlight, then recede into the crowd
    rec <- eo((tt - (st + HOLD)) / .9)                 # 0 = spotlit, 1 = background
    lvl <- 1 - 0.62 * rec
    dim <- 1 - 0.72 * eo((tt - 9.2) / .9)              # everything dims for the stamp
    a   <- ap * lvl * dim * out
    # a soft card sits behind the quote while it is spotlit
    hl <- ap * (1 - rec) * dim * out
    if (hl > .01) {
      wpx <- nchar(q[[5]]) * q[[3]] * 0.0093 + .035
      xL  <- if (q[[4]] == 0) q[[1]] - .018 else q[[1]] + .018 - wpx
      rect2(xL, q[[2]] - .009, wpx, .066, card, hl * .92)
      lin(xL, q[[2]] - .042, xL + wpx, q[[2]] - .042, rust, 2, hl)
    }
    txt(q[[1]], q[[2]], q[[5]], BODY, 3, q[[3]], q[[7]], a, adj = c(q[[4]], .5))
    txt(q[[1]], q[[2]] - .0245, q[[6]], MONO, 1, .47, mid, a * .9, adj = c(q[[4]], .5))
  }
  # the stamp
  as <- fi(tt, 9.4, .55) * out
  if (as > .001) {
    rect2(0, .50, 1, .185, bone, as, just = c("left", "centre"))
    lin(.06, .585, .94, .585, rust, 4, as)
    txt(.06, .535, "THEY ALL SAY IT.", DISP, 1, 3.4, ink, as)
    lin(.06, .445, .94, .445, rust, 4, as)
  }
  txt(.06, .400, "So we tested it. Five ways.", BODY, 1, 1.75, mid, fi(tt, 10.6, .55) * out)
}

# =====================================================================
# SCENE 3 - test 1, the third-down setup
# =====================================================================
s_down <- function(tt) {
  a <- fi(tt, 0, 0.517); out <- fo(tt, 12.4, .45)
  txt(.07, .875, "TEST 1  ·  THE NEXT PLAY", MONO, 2, 1.0, rust, a * out)
  txt(.07, .80, "Run, run, then throw", DISP, 1, 3.4, ink, fi(tt, 0.243, 0.575) * out)
  txt(.07, .735, "Third-down pass, by what the offense did on 1st & 2nd", BODY, 1, 1.55, mid, fi(tt, 0.486, 0.575) * out)
  txt(.07, .700, "3rd & 3 to 7, the distances that decide drives", BODY, 1, 1.55, mid, fi(tt, 0.486, 0.575) * out)

  zx <- .50; scale <- 2.9   # x-position of zero, and units->npc
  lin(zx, .36, zx, .615, rule, 2, fi(tt, 0.81, 0.46) * out)
  txt(zx, .645, "0", MONO, 1, .95, mid, fi(tt, 0.81, 0.46) * out, adj = c(.5, .5))

  # row 1: passed twice -> +0.03
  t1 <- cl((tt - 1.62) / 1.725); a1 <- fi(tt, 1.296, 0.46) * out
  v1 <- num(0, .03, t1)
  txt(.07, .565, "PASSED on 1st & 2nd", BODY, 2, 1.6, ink, a1)
  rect2(zx, .515, max(0, v1) * scale, .046, gain, a1)
  txt(zx + max(0, v1) * scale + .015, .538, sgn(v1), DISP, 1, 2.1, gain, a1, adj = c(0, .5))

  # row 2: ran twice -> -0.04
  t2 <- cl((tt - 3.726) / 1.725); a2 <- fi(tt, 2.916, 0.46) * out
  v2 <- num(0, -.04, t2)
  txt(.07, .445, "RAN on 1st & 2nd", BODY, 2, 1.6, ink, a2)
  rect2(zx + v2 * scale, .395, abs(v2) * scale, .046, rust, a2)
  txt(zx + v2 * scale - .015, .418, sgn(v2), DISP, 1, 2.1, rust, a2, adj = c(1, .5))

  # payoff
  a3 <- fi(tt, 7.452, 0.69) * out
  lin(.07, .335, .93, .335, rule, 2, a3)
  txt(.07, .265, "Grinding it first makes the", BODY, 1, 2.05, ink, a3)
  txt(.07, .215, "third-down throw WORSE.", DISP, 1, 2.6, rust, fi(tt, 8.262, 0.575) * out)
  txt(.07, .145, "EXPECTED POINTS PER PLAY  ·  2015-2025  ·  n = 666-2,549", MONO, 1, .82, mid, fi(tt, 9.072, 0.575) * out)
}

# =====================================================================
# SCENE 4 - test 2, the long game (dots collapse to zero)
# =====================================================================
s_long <- function(tt) {
  out <- fo(tt, 11.4, .52)
  txt(.07, .900, "TEST 2  ·  THE LONG GAME", MONO, 2, 1.0, rust, fi(tt, 0, .52) * out)
  txt(.07, .830, "Pound it early, throw it late", DISP, 1, 3.0, ink, fi(tt, .26, .58) * out)
  txt(.07, .766, "Does first-half running predict later passing?", BODY, 1, 1.55, mid, fi(tt, .51, .58) * out)
  # say plainly what is being measured
  ac <- fi(tt, .85, .58) * out
  txt(.07, .722, "Each dot is a CORRELATION: how much a team ran early,", BODY, 1, 1.24, mid, ac)
  txt(.07, .692, "against how well it threw later in the game.", BODY, 1, 1.24, mid, ac)

  zx <- .565; scale <- .95                 # zero position, and units -> npc
  xat <- function(v) zx + v * scale
  ab  <- fi(tt, 1.15, .58) * out

  rect2(xat(-.05), .345, .10 * scale, .295, "#b9d2c4", ab * .55, just = c("left", "bottom"))
  txt(zx, .652, "NO EFFECT", MONO, 2, .78, gain, ab, adj = c(.5, .5))
  lin(zx, .345, zx, .640, rule, 2, ab)
  ar <- fi(tt, 1.5, .58) * out
  lin(xat(.30), .345, xat(.30), .640, iron, 2, ar * .8, lty = 2)
  txt(xat(.30), .652, "A REAL EFFECT", MONO, 2, .78, iron, ar, adj = c(.5, .5))

  rows <- list(c("Later in the same half", -0.03), c("The second half", -0.05),
               c("The fourth quarter", -0.05), c("Play-action, 2nd half", -0.02))
  for (i in seq_along(rows)) {
    y  <- .592 - (i - 1) * .066
    ai <- fi(tt, 1.85 + i * .52, .52) * out
    tv <- cl((tt - (1.95 + i * .52)) / 1.38)
    v  <- 0.30 + (as.numeric(rows[[i]][2]) - 0.30) * eio(tv)
    txt(.07, y, rows[[i]][1], BODY, 1, 1.42, ink, ai)
    grid.circle(x = xat(v), y = y, r = .0128, gp = gpar(fill = rust, col = NA, alpha = cl(ai)))
    txt(xat(v), y + .030, sprintf("%+.2f", v), MONO, 2, .90, rust, ai, adj = c(.5, .5))
  }

  aa <- fi(tt, 5.0, .58) * out
  lin(xat(-.10), .318, xat(.36), .318, rule, 2, aa)
  txt(zx, .288, "0", MONO, 1, .82, mid, aa, adj = c(.5, .5))
  txt(xat(.30), .288, "+0.30", MONO, 1, .82, mid, aa, adj = c(.5, .5))
  txt(.07, .288, "CORRELATION", MONO, 2, .82, mid, aa)
  txt(.07, .258, "0 = no relationship at all", MONO, 1, .78, mid, fi(tt, 5.5, .58) * out)

  a4 <- fi(tt, 6.7, .69) * out
  lin(.07, .214, .93, .214, rule, 2, a4)
  txt(.07, .148, "Every horizon. Nothing.", DISP, 1, 2.6, rust, a4)
  txt(.07, .086, "Neutral game states only, so a lead isn't doing the work", MONO, 1, .82, mid,
      fi(tt, 7.5, .58) * out)
}

# =====================================================================
# SCENE 5 - test 3, the wear-down
# =====================================================================
s_wear <- function(tt) {
  out <- fo(tt, 12.4, .45)
  txt(.07, .875, "TEST 3  ·  THE WEAR-DOWN", MONO, 2, 1.0, rust, fi(tt, 0, 0.517) * out)
  txt(.07, .80, "The break doesn't show", DISP, 1, 3.0, ink, fi(tt, 0.243, 0.575) * out)
  txt(.07, .735, "Run success rate by quarter, neutral game states", BODY, 1, 1.55, mid, fi(tt, 0.486, 0.575) * out)

  x0 <- .12; x1 <- .90; yb <- .33; yt <- .64
  vals <- c(.394, .405, .397, .401)          # Q1..Q4 success
  yv <- function(v) yb + (v - .36) / (.48 - .36) * (yt - yb)
  ax <- fi(tt, 0.729, 0.517) * out
  lin(x0, yb, x1, yb, rule, 2, ax)
  for (i in 1:4) txt(x0 + (i - 1) / 3 * (x1 - x0), yb - .035, paste0("Q", i), MONO, 2, 1.0, mid, ax, adj = c(.5, .5))
  txt(x0 - .02, yv(.40), "40%", MONO, 1, .85, mid, ax, adj = c(1, .5))

  # ghost: what wearing down would look like
  ag <- fi(tt, 1.296, 0.575) * out
  pg <- cl((tt - 1.62) / 1.61)
  gx <- x0 + (x1 - x0) * pg
  lin(x0, yv(.394), gx, yv(.394 + (.455 - .394) * pg), iron, 3, ag * .55, lty = 2)
  txt(x1, yv(.462), "if defenses wore down", MONO, 1, .88, iron, fi(tt, 2.592, 0.575) * out * .8, adj = c(1, .5))

  # actual: flat line drawing across
  pa <- cl((tt - 3.078) / 2.07); aa <- fi(tt, 3.078, 0.345) * out
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
  a3 <- fi(tt, 5.832, 0.632) * out
  lin(.07, .285, .93, .285, rule, 2, a3)
  txt(.07, .215, "+0.00", DISP, 1, 3.6, rust, a3)
  txt(.07, .145, "early carries vs 4th-quarter running", BODY, 1, 1.6, ink, fi(tt, 6.642, 0.575) * out)
  a4 <- fi(tt, 7.776, 0.632) * out
  txt(.07, .092, "Attrition may well be real. Modern lines rotate,", MONO, 1, .82, mid, a4)
  txt(.07, .060, "and whatever it does never reaches the box score.", MONO, 1, .82, mid, a4)
}

# =====================================================================
# SCENE 6 - test 4, the reverse
# =====================================================================
s_rev <- function(tt) {
  out <- fo(tt, 16.4, .5)
  txt(.07, .905, "TEST 4  ·  THE REVERSE", MONO, 2, 1.0, rust, fi(tt, 0, 0.517) * out)
  txt(.07, .845, "So what DOES open up the run?", DISP, 1, 2.7, ink, fi(tt, 0.222, 0.575) * out)

  # ---- STEP 1: runs work against light boxes -------------------------
  a1 <- fi(tt, 1.332, 0.575) * out
  txt(.07, .775, "STEP 1", MONO, 2, .82, rust, a1)
  txt(.175, .775, "A run works when fewer defenders are in the box", BODY, 1, 1.35, mid, a1)
  rows <- list(list("6 or fewer in the box", .39, gain),
               list("7 in the box",          .37, iron),
               list("8 or more in the box",  .35, rust))
  bx <- .07; bw <- .60
  for (i in seq_along(rows)) {
    y  <- .700 - (i - 1) * .074
    ai <- fi(tt, 1.628 + i * 0.814, 0.575) * out
    tv <- cl((tt - (1.702 + i * 0.814)) / 1.495)
    v  <- num(0, rows[[i]][[2]], tv)
    txt(bx, y + .029, rows[[i]][[1]], BODY, 2, 1.28, ink, ai)
    rect2(bx, y - .014, bw * (v / .45), .030, rows[[i]][[3]], ai)
    txt(bx + bw * (v / .45) + .014, y, sprintf("%.0f%%", v * 100), DISP, 1, 1.7,
        rows[[i]][[3]], ai, adj = c(0, .5))
  }
  txt(.07, .506, "early-down run success rate", MONO, 1, .78, mid, fi(tt, 5.032, 0.575) * out)

  # ---- STEP 2: throwing is what empties the box ----------------------
  a2 <- fi(tt, 6.512, 0.632) * out
  lin(.07, .466, .93, .466, rule, 2, a2)
  txt(.07, .416, "STEP 2", MONO, 2, .82, rust, a2)
  txt(.175, .416, "And throwing is what empties the box", BODY, 1, 1.35, mid, a2)

  # causal chain: more passing -> lighter box -> runs work
  cy <- .322; bw2 <- .255; bh <- .078
  chain <- list(list(.07,  "THE MORE\nYOU THROW",   rust),
                list(.375, "THE LIGHTER\nTHE BOX",  iron),
                list(.68,  "THE BETTER\nRUNS WORK", gain))
  for (i in seq_along(chain)) {
    ac <- fi(tt, 7.4 + (i - 1) * 1.184, 0.575) * out
    cx <- chain[[i]][[1]]
    if (ac > .001) {
      grid.rect(x = cx, y = cy, width = bw2, height = bh, just = c("left", "centre"),
                gp = gpar(fill = card, col = chain[[i]][[3]], lwd = 2, alpha = cl(ac)))
      txt(cx + bw2 / 2, cy, chain[[i]][[2]], BODY, 2, 1.16, chain[[i]][[3]], ac,
          adj = c(.5, .5), lh = 1.05)
    }
    if (i < 3) {
      aa <- fi(tt, 7.992 + (i - 1) * 1.184, 0.46) * out
      if (aa > .001)
        grid.segments(x0 = cx + bw2 + .008, x1 = cx + bw2 + .040, y0 = cy, y1 = cy,
                      gp = gpar(col = ink, lwd = 3, alpha = cl(aa)),
                      arrow = arrow(length = unit(5, "pt"), type = "closed"))
    }
  }
  a3 <- fi(tt, 10.952, 0.632) * out
  txt(.07, .240, sprintf("+%.2f", num(0, 0.51, cl((tt - 11.1) / 1.61))), DISP, 1, 2.3, gain, a3)
  txt(.205, .258, "CORRELATION between how much a team throws", BODY, 1, 1.28, ink, a3)
  txt(.205, .225, "and how light a box its runs face", BODY, 1, 1.28, ink, a3)

  # ---- payoff --------------------------------------------------------
  a5 <- fi(tt, 13.024, 0.69) * out
  lin(.07, .192, .93, .192, rule, 2, a5)
  txt(.07, .134, "You don't run to set up the pass.", BODY, 1, 1.82, mid, a5)
  txt(.07, .076, "You throw to open up the run.", DISP, 1, 2.45, ink, fi(tt, 13.912, 0.632) * out)
}

# =====================================================================
# SCENE 7 - December, the grain of truth
# =====================================================================
s_dec <- function(tt) {
  out <- fo(tt, 11.4, .45)
  txt(.07, .885, "THE GRAIN OF TRUTH", MONO, 2, 1.0, rust, fi(tt, 0, 0.517) * out)
  txt(.07, .815, "December football", DISP, 1, 3.4, ink, fi(tt, 0.257, 0.575) * out)
  txt(.07, .750, "How much better passing is than running, by temperature", BODY, 1, 1.5, mid, fi(tt, 0.513, 0.575) * out)

  x0 <- .13; x1 <- .90; yb <- .36; yt <- .655
  vals <- c(.15, .12, .09, .04); labs <- c("70F+", "46-55", "26-35", "<25F")
  yv <- function(v) yb + (v / .18) * (yt - yb)
  ax <- fi(tt, 0.769, 0.517) * out
  lin(x0, yb, x1, yb, ink, 3, ax)                                  # zero line
  txt(x0, yb - .035, "0  ·  running is the better call below this line", MONO, 1, .84, mid, ax)
  for (i in 1:4) txt(x0 + (i - 1)/3 * (x1 - x0), yt + .045, labs[i], MONO, 2, .95, mid, ax, adj = c(.5, .5))

  pa <- cl((tt - 1.71) / 2.3); aa <- fi(tt, 1.454, 0.402) * out
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
  a3 <- fi(tt, 6.156, 0.632) * out
  lin(.07, .295, .93, .295, rule, 2, a3)
  txt(.07, .225, "The edge nearly vanishes.", BODY, 1, 1.95, ink, a3)
  txt(.07, .160, "It never flips.", DISP, 1, 3.0, rust, fi(tt, 7.011, 0.575) * out)
  txt(.07, .092, "Throwing stays the better bet even on a frozen field", MONO, 1, .84, mid, fi(tt, 7.866, 0.575) * out)
}

# =====================================================================
# SCENE 8 - verdict
# =====================================================================
s_verd <- function(tt) {
  a <- fi(tt, 0, 0.575)
  txt(.07, .855, "THE VERDICT", MONO, 2, 1.05, rust, a)
  ls <- list(c("The run does not set up the pass.", ink),
             c("The wear-down never shows up.", ink),
             c("Passing is what opens the run.", rust))
  for (i in seq_along(ls)) {
    txt(.07, .745 - (i - 1) * .085, ls[[i]][1], DISP, 1, 2.7, ls[[i]][2], fi(tt, 0.623 + i * 0.676, 0.575))
  }
  a2 <- fi(tt, 4.094, 0.69)
  lin(.07, .445, .93, .445, rule, 2, a2)
  txt(.07, .375, "The one thing the grinders get right", BODY, 1, 1.8, mid, a2)
  txt(.07, .325, "is the weather.", BODY, 1, 1.8, mid, a2)
  a3 <- fi(tt, 5.34, 0.69)
  txt(.07, .195, "nflverse play-by-play", DISP, 1, 2.0, ink, a3)
  txt(.07, .142, "2015 to 2025  ·  neutral game states  ·  analysis in R", MONO, 1, .85, mid, a3)
}

# =====================================================================
# render
# =====================================================================
chap <- function(tt_name) switch(tt_name,
  title = NULL, claim = NULL, quotes = NULL, down = "THE GRIND", long = "THE GRIND",
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
  switch(nm, title = s_title(tt), claim = s_claim(tt), quotes = s_quotes(tt),
         down = s_down(tt), long = s_long(tt),
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
