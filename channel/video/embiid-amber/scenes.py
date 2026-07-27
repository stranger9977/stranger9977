"""Embiid — "Amber" — scene set.

Every number here comes from the Embiid availability piece. Nothing is
invented. Anything not yet verified is absent rather than approximated.

Render one:   manim -qh --fps 30 scenes.py A1_Setup
Render all:   see build.sh
"""

from manim import *
from house import *


# ==================================================================
# ACT 1 — THE RECORD
# ==================================================================

class A1_Setup(HouseScene):
    """Establish the 78 games and the three states. No argument yet."""

    def construct(self):
        self.bignum("78", "playoff games", hold=HOLD)
        self.clear_all()

        t = self.statement("Eight postseasons.", 40, hold=HOLD_SHORT)
        t = self.swap(t, "One body.", 40, hold=HOLD)
        self.clear_all()

        grid = games_grid().move_to(ORIGIN)
        self.play(LaggedStart(*[FadeIn(d, scale=0.6) for d in grid],
                              lag_ratio=0.012), run_time=2.0)
        self.wait(HOLD_SHORT)

        healthy, hurt, missed = paint(grid)

        cap = txt("12 he missed entirely", 32).next_to(grid, DOWN, buff=0.8)
        self.play(*[d.animate.set_fill(GROUND).set_stroke(RED, 2.5)
                    for d in missed], run_time=1.0)
        self.play(FadeIn(cap), run_time=0.6)
        self.wait(HOLD)
        self.play(FadeOut(cap), run_time=0.45)

        cap = txt("52 he played hurt", 32).next_to(grid, DOWN, buff=0.8)
        self.play(*[d.animate.set_fill(AMBER) for d in hurt], run_time=1.2)
        self.play(FadeIn(cap), run_time=0.6)
        self.wait(HOLD_LONG)
        self.play(FadeOut(cap), run_time=0.45)

        cap = txt("14 he started healthy", 32).next_to(grid, DOWN, buff=0.8)
        self.play(*[d.animate.set_fill(BONE) for d in healthy], run_time=1.0)
        self.play(FadeIn(cap), run_time=0.6)
        self.wait(HOLD_LONG)
        self.play(FadeOut(cap), run_time=0.45)

        cap = txt("One colour is doing most of the work.",
                  32, AMBER).next_to(grid, DOWN, buff=0.8)
        self.play(FadeIn(cap), run_time=0.8)
        self.wait(HOLD_LAND)
        self.clear_all()


class A1_TheQuestion(HouseScene):
    """Frame the belief on trial. Two myths, stated plainly."""

    def construct(self):
        t = self.statement("Everybody knows two things", 38, DIM,
                           hold=HOLD_SHORT)
        self.clear_all(0.6)

        one = txt("Seven-footers break.", 42).move_to(UP * 0.8)
        self.play(FadeIn(one, shift=UP * 0.15), run_time=0.8)
        self.wait(HOLD)

        two = txt("And hurt Embiid can't play.", 42).move_to(DOWN * 0.5)
        self.play(FadeIn(two, shift=UP * 0.15), run_time=0.8)
        self.wait(HOLD_LONG)

        self.play(FadeOut(VGroup(one, two)), run_time=0.7)
        self.wait(0.4)

        self.statement("Neither one survives the data intact.",
                       38, AMBER, hold=HOLD_LAND)
        self.clear_all()


# ==================================================================
# ACT 3 — MYTH TWO: HE PLAYS BADLY HURT
# ==================================================================

class A3_RawSplit(HouseScene):
    """The number that looks damning. State it at full strength first."""

    def construct(self):
        k = self.kicker("Myth two · he can't play hurt")
        self.wait(0.8)

        t = self.statement("True shooting percentage.", 36, DIM, hold=HOLD_SHORT)
        self.play(FadeOut(t), run_time=0.5)

        # Two bars, healthy vs hurt.
        scale = 14.0
        h_val, u_val = 0.646, 0.559

        h_bar = bar(h_val * scale, 0.62, BONE)
        u_bar = bar(u_val * scale, 0.62, AMBER)
        h_bar.move_to(UP * 0.9).align_to(LEFT * 5.2, LEFT)
        u_bar.move_to(DOWN * 0.5).align_to(LEFT * 5.2, LEFT)

        h_lab = txt("healthy", 26, DIM).next_to(h_bar, UP, buff=0.22).align_to(h_bar, LEFT)
        u_lab = txt("hurt", 26, DIM).next_to(u_bar, UP, buff=0.22).align_to(u_bar, LEFT)
        h_n = txt(".646", 34, BONE).next_to(h_bar, RIGHT, buff=0.3)
        u_n = txt(".559", 34, AMBER).next_to(u_bar, RIGHT, buff=0.3)

        self.play(FadeIn(h_lab), GrowFromEdge(h_bar, LEFT), run_time=1.0)
        self.play(FadeIn(h_n), run_time=0.5)
        self.wait(HOLD_SHORT)
        self.play(FadeIn(u_lab), GrowFromEdge(u_bar, LEFT), run_time=1.0)
        self.play(FadeIn(u_n), run_time=0.5)
        self.wait(HOLD)

        gap = txt("87 points", 44, CLAY).move_to(DOWN * 2.1)
        self.play(FadeIn(gap, shift=UP * 0.15), run_time=0.8)
        self.wait(HOLD)

        sub = txt("the distance between the best offence in the league\nand one of the worst",
                  27, DIM).next_to(gap, DOWN, buff=0.35)
        self.play(FadeIn(sub), run_time=0.7)
        self.wait(HOLD_LAND)
        self.clear_all()

        self.statement("That number is wrong.", 42, AMBER, hold=HOLD_LAND,
                       weight=BOLD)
        self.clear_all()


class A3_Correction(HouseScene):
    """Two corrections, applied one at a time. This is the honest core."""

    def construct(self):
        k = self.kicker("Correction one · the soft series")
        self.wait(0.6)

        t = self.statement("Eleven healthy games.", 38, hold=HOLD_SHORT)
        t = self.swap(t, "Four of them against Washington.", 38, hold=HOLD)
        t = self.swap(t, "No rim protection. He shot .750.", 38, AMBER, hold=HOLD)
        t = self.swap(t, "The best mark of his playoff life.", 34, DIM,
                      hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("Set that series aside.", 38, hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        # .646 -> .602
        before = txt(".646", 92, DIM).move_to(LEFT * 2.4)
        arrow = txt("→", 60, DIM).move_to(ORIGIN)
        after = txt(".602", 92, BONE).move_to(RIGHT * 2.4)
        self.play(FadeIn(before), run_time=0.7)
        self.wait(HOLD_SHORT)
        self.play(FadeIn(arrow), FadeIn(after), run_time=0.8)
        self.wait(HOLD)
        cap = txt("seven games left, and now under his own regular season",
                  27, DIM).next_to(VGroup(before, after), DOWN, buff=0.7)
        self.play(FadeIn(cap), run_time=0.7)
        self.wait(HOLD_LONG)
        self.clear_all()

        # --- correction two -------------------------------------------
        k = self.kicker("Correction two · the playoff tax")
        self.wait(0.6)

        t = self.statement("Every star gets worse in May.", 38, hold=HOLD)
        t = self.swap(t, "They lose the weak opponents. They draw the scheme.",
                      34, DIM, hold=HOLD)
        t = self.swap(t, "Embiid's career playoff true shooting:", 34, DIM,
                      hold=HOLD_SHORT)
        self.play(FadeOut(t), run_time=0.5)

        a = txt(".613", 76, DIM).move_to(LEFT * 2.4)
        al = txt("regular season", 24, DIM).next_to(a, DOWN, buff=0.3)
        b = txt(".578", 76, AMBER).move_to(RIGHT * 2.4)
        bl = txt("playoffs", 24, DIM).next_to(b, DOWN, buff=0.3)
        self.play(FadeIn(VGroup(a, al)), run_time=0.7)
        self.wait(HOLD_SHORT)
        self.play(FadeIn(VGroup(b, bl)), run_time=0.7)
        self.wait(HOLD)
        cap = txt("across every health state", 27, DIM).move_to(DOWN * 2.2)
        self.play(FadeIn(cap), run_time=0.6)
        self.wait(HOLD)
        self.clear_all()

        t = self.statement("So subtract the playoff tax from both sides.",
                           36, hold=HOLD_LONG)
        self.clear_all(0.6)

        # The landing number.
        n = num("38", 170, AMBER)
        c = txt("points of true shooting", 30, DIM).next_to(n, DOWN, buff=0.4)
        g = VGroup(n, c).move_to(UP * 0.4)
        self.play(FadeIn(n, shift=UP * 0.2), run_time=0.9)
        self.play(FadeIn(c), run_time=0.6)
        self.wait(HOLD_LONG)

        ci = txt("80% interval:  −66 to −2", 30, DIM).next_to(g, DOWN, buff=0.9)
        self.play(FadeIn(ci), run_time=0.7)
        self.wait(HOLD)
        boot = txt("hurt games come out worse in 92% of resamples",
                   27, DIM).next_to(ci, DOWN, buff=0.35)
        self.play(FadeIn(boot), run_time=0.7)
        self.wait(HOLD_LONG)
        self.clear_all()

        t = self.statement("The direction is solid.", 40, hold=HOLD)
        self.swap(t, "The size is not.", 40, AMBER, hold=HOLD_LAND)
        self.clear_all()


class A3_Defense(HouseScene):
    """The null — and the honest admission that the test had no power."""

    def construct(self):
        k = self.kicker("The other end of the floor")
        self.wait(0.6)

        t = self.statement("Three-time All-Defensive centre.", 36, hold=HOLD_SHORT)
        t = self.swap(t, "So the injuries should show up in the rim protection.",
                      34, DIM, hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        rows = [("blocks", "1.46", "1.86"),
                ("def. rebounds", "9.84", "8.45"),
                ("steals", "1.34", "0.75")]

        head = VGroup(
            txt("per 36", 24, DIM),
            txt("healthy", 24, DIM),
            txt("hurt", 24, DIM),
        ).arrange(RIGHT, buff=1.7)
        head[0].shift(LEFT * 0.6)

        table = VGroup(head)
        for name, hv, uv in rows:
            r = VGroup(txt(name, 28, BONE), txt(hv, 30, BONE), txt(uv, 30, AMBER))
            r.arrange(RIGHT, buff=1.7)
            table.add(r)
        table.arrange(DOWN, buff=0.55, aligned_edge=LEFT).move_to(UP * 0.3)

        self.play(FadeIn(head), run_time=0.6)
        for r in table[1:]:
            self.play(FadeIn(r), run_time=0.6)
            self.wait(0.9)
        self.wait(HOLD)

        cap = txt("He blocks more shots hurt than healthy.",
                  32, AMBER).next_to(table, DOWN, buff=0.9)
        self.play(FadeIn(cap), run_time=0.8)
        self.wait(HOLD_LONG)
        self.clear_all()

        t = self.statement("Which points the wrong way for the story.",
                           36, hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("So check whether the test could find anything at all.",
                           34, DIM, hold=HOLD_LONG)
        self.clear_all(0.6)

        # The power analysis — the best beat in the film.
        n = num("1.22", 130, CLAY)
        c = txt("the smallest block-rate gap this sample could detect",
                28, DIM).next_to(n, DOWN, buff=0.45)
        g = VGroup(n, c).move_to(UP * 0.5)
        if g.width > 12:
            g.scale_to_fit_width(12)
        self.play(FadeIn(n, shift=UP * 0.2), run_time=0.9)
        self.play(FadeIn(c), run_time=0.7)
        self.wait(HOLD_LONG)

        sub = txt("against a career rate of 1.79", 30, DIM).next_to(g, DOWN, buff=0.8)
        self.play(FadeIn(sub), run_time=0.7)
        self.wait(HOLD)
        sub2 = txt("a 68% swing", 34, AMBER).next_to(sub, DOWN, buff=0.35)
        self.play(FadeIn(sub2), run_time=0.7)
        self.wait(HOLD_LONG)
        self.clear_all()

        t = self.statement("This test has no power.", 42, weight=BOLD, hold=HOLD_LONG)
        t = self.swap(t, "It could not tell a hurt Embiid from a healthy one",
                      34, DIM, hold=HOLD_SHORT)
        t = self.swap(t, "unless the difference were enormous.", 34, DIM,
                      hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)
        self.statement("His defence under injury is unmeasured.\nNot unaffected.",
                       36, AMBER, hold=HOLD_LAND)
        self.clear_all()


# ==================================================================
# ACT 4 — THE TURN
# ==================================================================

class A4_Scoreboard(HouseScene):
    """The screenshot number, then the round control that kills it."""

    def construct(self):
        k = self.kicker("The scoreboard")
        self.wait(0.6)

        t = self.statement("Efficiency is a proxy. Wins are the thing.",
                           36, hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        rows = [("healthy", "9–5", ".643", BONE),
                ("hurt", "23–29", ".442", AMBER),
                ("not playing", "6–6", ".500", RED)]
        table = VGroup()
        for name, rec, pct, col in rows:
            r = VGroup(txt(name, 30, col), txt(rec, 30, DIM), txt(pct, 34, col))
            r.arrange(RIGHT, buff=1.5)
            table.add(r)
        table.arrange(DOWN, buff=0.6, aligned_edge=LEFT).move_to(UP * 0.4)

        for r in table:
            self.play(FadeIn(r), run_time=0.7)
            self.wait(1.0)
        self.wait(HOLD)

        cap = txt("Philadelphia looks better with him on the bench\nthan with him at 80 percent.",
                  32, CLAY).next_to(table, DOWN, buff=0.8)
        self.play(FadeIn(cap), run_time=0.9)
        self.wait(HOLD_LAND)
        self.clear_all()

        t = self.statement("That number will get screenshotted.", 38, hold=HOLD)
        self.swap(t, "It is almost certainly wrong.", 38, AMBER, hold=HOLD_LAND)
        self.clear_all()


class A4_Confound(HouseScene):
    """The finding the whole piece is actually about."""

    def construct(self):
        k = self.kicker("Split it by round")
        self.wait(0.6)

        first = VGroup(
            txt("FIRST ROUNDS", 26, DIM),
            VGroup(txt("healthy", 28, BONE), txt(".643", 34, BONE)).arrange(RIGHT, buff=1.2),
            VGroup(txt("hurt", 28, AMBER), txt(".600", 34, AMBER)).arrange(RIGHT, buff=1.2),
        ).arrange(DOWN, buff=0.45, aligned_edge=LEFT).move_to(UP * 0.9)

        self.play(FadeIn(first[0]), run_time=0.6)
        self.play(FadeIn(first[1]), run_time=0.6)
        self.wait(0.9)
        self.play(FadeIn(first[2]), run_time=0.6)
        self.wait(HOLD)

        cap = txt("A difference of one game.", 34, BONE).next_to(first, DOWN, buff=0.9)
        self.play(FadeIn(cap), run_time=0.8)
        self.wait(HOLD_LONG)
        self.clear_all()

        # Every second round game is amber.
        k = self.kicker("Second rounds")
        row = VGroup(*[Square(side_length=0.42, fill_opacity=1,
                             fill_color=AMBER, stroke_width=0)
                      for _ in range(32)])
        row.arrange_in_grid(rows=2, cols=16, buff=0.15).move_to(UP * 0.5)
        self.play(LaggedStart(*[FadeIn(d, scale=0.6) for d in row],
                              lag_ratio=0.03), run_time=2.0)
        self.wait(HOLD_SHORT)

        cap = txt("Thirty-two games. Eleven and twenty-one.",
                  32, DIM).next_to(row, DOWN, buff=0.8)
        self.play(FadeIn(cap), run_time=0.7)
        self.wait(HOLD)
        cap2 = txt("Every one of them amber.", 36, AMBER).next_to(cap, DOWN, buff=0.4)
        self.play(FadeIn(cap2), run_time=0.8)
        self.wait(HOLD_LAND)
        self.clear_all()

        t = self.statement("Joel Embiid has never played\na healthy second-round game.",
                           40, weight=BOLD, hold=HOLD_LAND)
        self.play(FadeOut(t), run_time=0.6)

        t = self.statement("Not once in ten years.", 38, AMBER, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("So health and round cannot be separated.", 36,
                           hold=HOLD)
        t = self.swap(t, "Every healthy game is a first-round game.", 34, DIM,
                      hold=HOLD)
        t = self.swap(t, "Controlling for one always controls for part of the other.",
                      32, DIM, hold=HOLD)
        self.swap(t, "No amount of arithmetic gets around it.", 36, CLAY,
                  hold=HOLD_LAND)
        self.clear_all()


class A4_Everybody(HouseScene):
    """Amber is not unique. What it costs is."""

    def construct(self):
        k = self.kicker("Everybody is hurt in May")
        self.wait(0.6)

        t = self.statement("Jaylen Brown started all eleven games", 34,
                           hold=HOLD_SHORT)
        t = self.swap(t, "of a title defence on a torn meniscus.", 34, AMBER,
                      hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("Tyrese Maxey played a whole postseason", 34,
                           hold=HOLD_SHORT)
        t = self.swap(t, "in a splint, with a torn tendon in his pinky.",
                      34, AMBER, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("Nobody has ever painted their squares amber.",
                           34, DIM, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        self.statement("Amber is not unique to Embiid.", 40, hold=HOLD_LAND)
        self.clear_all()

        t = self.statement("The difference is what the hurt costs.", 38,
                           hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        a = txt("Brown at 80 percent gives back a step.", 34, DIM).move_to(UP * 0.7)
        self.play(FadeIn(a), run_time=0.8)
        self.wait(HOLD)
        b = txt("Embiid at 80 percent gives back the offence.",
                34, AMBER).move_to(DOWN * 0.4)
        self.play(FadeIn(b), run_time=0.8)
        self.wait(HOLD)
        c = txt("because he is the offence", 30, DIM).next_to(b, DOWN, buff=0.5)
        self.play(FadeIn(c), run_time=0.7)
        self.wait(HOLD_LAND)
        self.clear_all()


class A4_TheRed(HouseScene):
    """The reversal. It was never the amber."""

    def construct(self):
        grid = games_grid().move_to(UP * 0.5)
        healthy, hurt, missed = paint(grid)
        healthy.set_fill(BONE)
        hurt.set_fill(AMBER)
        for d in missed:
            d.set_fill(GROUND).set_stroke(RED, 2.5)

        self.play(FadeIn(grid), run_time=1.2)
        self.wait(HOLD_SHORT)

        t = txt("The thing that has cost Philadelphia", 34,
                DIM).next_to(grid, DOWN, buff=0.9)
        self.play(FadeIn(t), run_time=0.8)
        self.wait(HOLD)

        self.play(hurt.animate.set_fill(GRID),
                  healthy.animate.set_fill(GRID), run_time=1.3)
        self.play(*[d.animate.set_stroke(RED, 4) for d in missed],
                  run_time=0.8)
        self.wait(HOLD_SHORT)

        t2 = txt("is not the amber.", 36, BONE).move_to(t)
        self.play(FadeOut(t), run_time=0.4)
        self.play(FadeIn(t2), run_time=0.7)
        self.wait(HOLD_LONG)
        self.clear_all()

        t = self.statement("It is the twelve red squares.", 40, RED,
                           hold=HOLD_LONG, weight=BOLD)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("And the fact that he has arrived", 36,
                           hold=HOLD_SHORT)
        t = self.swap(t, "at every second round of his career", 36, hold=HOLD_SHORT)
        self.swap(t, "already hurt.", 40, AMBER, hold=HOLD_LAND)
        self.clear_all()


class A4_Stakes(HouseScene):
    """What it's worth. The close."""

    def construct(self):
        k = self.kicker("What his health is worth")
        self.wait(0.6)

        t = self.statement("The market has Philadelphia at 12 percent.",
                           36, hold=HOLD)
        t = self.swap(t, "That price already has his history baked in.",
                      34, DIM, hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("Guarantee him healthy every night.", 36, hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        a = txt("12%", 110, DIM).move_to(LEFT * 3.0)
        arrow = txt("→", 56, DIM).move_to(LEFT * 0.6)
        b = txt("19–41%", 110, AMBER).move_to(RIGHT * 2.4)
        self.play(FadeIn(a), run_time=0.8)
        self.wait(HOLD_SHORT)
        self.play(FadeIn(arrow), FadeIn(b), run_time=0.9)
        self.wait(HOLD_LONG)

        cap = txt("Between 1.7 and 3.7 times their current odds.",
                  30, DIM).move_to(DOWN * 1.8)
        self.play(FadeIn(cap), run_time=0.7)
        self.wait(HOLD)
        self.clear_all()

        self.statement("Half of Philadelphia's championship equity\nis sitting on one man's body.",
                       38, weight=BOLD, hold=HOLD_LAND)
        self.clear_all()

        # The availability model — the last image.
        t = self.statement("Over a twenty-game run", 34, DIM, hold=HOLD_SHORT)
        self.play(FadeOut(t), run_time=0.5)

        n = num("1.5", 150, BONE)
        c = txt("games expected at full health", 30, DIM).next_to(n, DOWN, buff=0.4)
        g = VGroup(n, c).move_to(ORIGIN)
        self.play(FadeIn(n, shift=UP * 0.2), run_time=0.9)
        self.play(FadeIn(c), run_time=0.6)
        self.wait(HOLD_LAND)
        self.clear_all()

        t = self.statement("The Sixers will go as far as", 36, DIM,
                           hold=HOLD_SHORT)
        self.swap(t, "Joel Embiid's health takes them.", 40, BONE,
                  hold=HOLD_LAND)
        self.clear_all()
