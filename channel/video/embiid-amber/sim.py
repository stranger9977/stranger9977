"""HOW WE SIMULATE — the mechanism act.

This is what Manim is actually for. Charts report a finding; this shows the
machine that produced it. Nobody else in sports YouTube can make this
scene, because nobody else built the model.

Structure follows concrete-before-abstract: one game, then one run, then
ten runs, then ten thousand, and only then the number. The viewer should
be able to rebuild the method from memory afterwards.

Determinism: fixed seed, so the same source produces the same film.
"""

import random

from manim import *
from house import *

SEED = 20260727

# Per-game state probabilities from the availability model.
P_HEALTHY, P_HURT, P_OUT = 0.075, 0.725, 0.200
RUN = 20


def draw(rng):
    r = rng.random()
    if r < P_HEALTHY:
        return "healthy"
    if r < P_HEALTHY + P_HURT:
        return "hurt"
    return "out"


COLOUR = {"healthy": BONE, "hurt": AMBER, "out": None}


def cell(state, side=0.3):
    sq = Square(side_length=side, stroke_width=0, fill_opacity=1)
    if state == "out":
        sq.set_fill(GROUND).set_stroke(RED, 2)
    else:
        sq.set_fill(COLOUR[state])
    return sq


class S1_OneGame(HouseScene):
    """The atom. One game is a weighted three-sided coin."""

    def construct(self):
        k = self.kicker("How we simulate")
        self.wait(0.6)

        t = self.statement("Everything so far has been a count.", 36, DIM,
                           hold=HOLD_SHORT)
        t = self.swap(t, "This is the part that predicts.", 38, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("Start with one game.", 40, hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        # The three outcomes, weighted.
        rows = [("starts healthy", "7.5%", P_HEALTHY, BONE),
                ("starts hurt", "72.5%", P_HURT, AMBER),
                ("does not play", "20%", P_OUT, RED)]
        group = VGroup()
        for name, pct, val, col in rows:
            lab = txt(name, 28, DIM)
            b = bar(val * 9.0, 0.5, col)
            n = txt(pct, 30, col)
            lab.move_to(LEFT * 4.2, aligned_edge=RIGHT)
            b.next_to(lab, RIGHT, buff=0.5).align_to(lab, DOWN)
            n.next_to(b, RIGHT, buff=0.35)
            group.add(VGroup(lab, b, n))
        group.arrange(DOWN, buff=0.7, aligned_edge=LEFT).move_to(UP * 0.3)

        for r in group:
            self.play(FadeIn(r[0]), GrowFromEdge(r[1], LEFT), run_time=0.8)
            self.play(FadeIn(r[2]), run_time=0.4)
            self.wait(0.9)
        self.wait(HOLD)

        cap = txt("A weighted coin with three sides.",
                  32, BONE).next_to(group, DOWN, buff=0.9)
        self.play(FadeIn(cap), run_time=0.8)
        self.wait(HOLD_LONG)
        self.clear_all()


class S2_OneRun(HouseScene):
    """Twenty flips is a title run. Watch one happen."""

    def construct(self):
        k = self.kicker("One title run")
        self.wait(0.6)

        t = self.statement("Four best-of-sevens. Call it twenty games.",
                           36, hold=HOLD)
        t = self.swap(t, "Flip the coin twenty times.", 36, hold=HOLD_SHORT)
        self.play(FadeOut(t), run_time=0.5)

        rng = random.Random(SEED)
        states = [draw(rng) for _ in range(RUN)]

        slots = VGroup(*[Square(side_length=0.44, stroke_width=1.5,
                               stroke_color=GRID, fill_opacity=0)
                        for _ in range(RUN)])
        slots.arrange_in_grid(rows=2, cols=10, buff=0.18).move_to(UP * 0.6)
        self.play(FadeIn(slots), run_time=0.8)
        self.wait(0.8)

        filled = VGroup()
        for i, st in enumerate(states):
            c = cell(st, 0.44).move_to(slots[i])
            filled.add(c)
            self.play(FadeIn(c, scale=0.7), run_time=0.16)
        self.wait(HOLD)

        n_h = sum(1 for s in states if s == "healthy")
        n_u = sum(1 for s in states if s == "hurt")
        n_o = sum(1 for s in states if s == "out")

        cap = txt(f"{n_h} healthy   ·   {n_u} hurt   ·   {n_o} missed",
                  32, BONE).next_to(slots, DOWN, buff=1.0)
        self.play(FadeIn(cap), run_time=0.8)
        self.wait(HOLD_LONG)
        self.play(FadeOut(cap), run_time=0.5)

        cap2 = txt("That is one possible June.", 34, DIM).next_to(slots, DOWN, buff=1.0)
        self.play(FadeIn(cap2), run_time=0.8)
        self.wait(HOLD)
        cap3 = txt("It is not a prediction. It is one draw.",
                   32, AMBER).next_to(cap2, DOWN, buff=0.4)
        self.play(FadeIn(cap3), run_time=0.8)
        self.wait(HOLD_LAND)
        self.clear_all()


class S3_ManyRuns(HouseScene):
    """Ten runs. The point where the viewer sees why one isn't enough."""

    def construct(self):
        k = self.kicker("So run it again")
        self.wait(0.6)

        rng = random.Random(SEED + 1)
        n_rows = 10
        runs = VGroup()
        for _ in range(n_rows):
            states = [draw(rng) for _ in range(RUN)]
            row = VGroup(*[cell(s, 0.26) for s in states])
            row.arrange(RIGHT, buff=0.08)
            runs.add(row)
        runs.arrange(DOWN, buff=0.14).move_to(UP * 0.2)

        for row in runs:
            self.play(FadeIn(row, shift=RIGHT * 0.2), run_time=0.32)
            self.wait(0.22)
        self.wait(HOLD)

        cap = txt("Ten different Junes.", 34, BONE).next_to(runs, DOWN, buff=0.8)
        self.play(FadeIn(cap), run_time=0.8)
        self.wait(HOLD)
        self.play(FadeOut(cap), run_time=0.45)

        cap = txt("None of them is the answer.", 34, DIM).next_to(runs, DOWN, buff=0.8)
        self.play(FadeIn(cap), run_time=0.8)
        self.wait(HOLD)
        cap2 = txt("The spread between them is.", 36, AMBER).next_to(cap, DOWN, buff=0.4)
        self.play(FadeIn(cap2), run_time=0.8)
        self.wait(HOLD_LAND)
        self.clear_all()


class S4_TenThousand(HouseScene):
    """The distribution emerges. This is the payoff beat."""

    def construct(self):
        k = self.kicker("Now do it ten thousand times")
        self.wait(0.6)

        rng = random.Random(SEED + 2)
        N = 10000
        counts = [0] * (RUN + 1)
        for _ in range(N):
            h = sum(1 for _ in range(RUN) if draw(rng) == "healthy")
            counts[h] += 1

        # Bars occupy the lower half only, so the callout has clean air above.
        top = max(counts)
        max_h = 9  # everything above this is empty; keep the axis honest but tight
        bars = VGroup()
        labels = VGroup()
        for i in range(max_h + 1):
            hgt = 3.0 * counts[i] / top
            b = Rectangle(width=0.72, height=max(hgt, 0.012),
                          fill_opacity=1, fill_color=AMBER, stroke_width=0)
            bars.add(b)
            labels.add(txt(str(i), 24, DIM))
        bars.arrange(RIGHT, buff=0.16, aligned_edge=DOWN)
        bars.move_to(DOWN * 2.4, aligned_edge=DOWN)
        for lab, b in zip(labels, bars):
            lab.next_to(b, DOWN, buff=0.22)

        axis = txt("games started at full health, out of twenty", 25, DIM)
        axis.next_to(labels, DOWN, buff=0.4)

        self.play(FadeIn(axis), FadeIn(labels), run_time=0.7)
        self.play(LaggedStart(*[GrowFromEdge(b, DOWN) for b in bars],
                              lag_ratio=0.06), run_time=2.2)
        self.wait(HOLD_LONG)

        # Hand the top of the frame from the kicker to the finding.
        cap = txt("Ten thousand Junes.", 34, BONE).move_to(UP * 2.1)
        self.play(FadeOut(self._kicker), run_time=0.4)
        self._kicker = None
        self.play(FadeIn(cap), run_time=0.8)
        self.wait(HOLD)
        self.play(FadeOut(cap), run_time=0.45)

        mean = sum(i * counts[i] for i in range(RUN + 1)) / N
        baseline = Line(bars[0].get_corner(DL) + DOWN * 0.04,
                        bars[max_h].get_corner(DR) + DOWN * 0.04,
                        stroke_width=2, color=GRID)
        self.play(Create(baseline), run_time=0.6)

        m = txt(f"{mean:.1f}", 84, BONE).move_to(UP * 2.3)
        mc = txt("games expected at full health", 27, DIM).next_to(m, DOWN, buff=0.28)
        self.play(FadeIn(VGroup(m, mc)), run_time=0.9)
        self.wait(HOLD_LAND)
        self.clear_all()


class S5_TheAnswer(HouseScene):
    """What the distribution is actually for."""

    def construct(self):
        t = self.statement("That distribution is the model.", 38, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("Read off any question you like.", 34, DIM,
                           hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        qs = [("He starts all twenty games", "2.3%", AMBER),
              ("All twenty, never compromised", "0.16%", RED)]
        group = VGroup()
        for q, a, col in qs:
            lab = txt(q, 30, DIM)
            val = txt(a, 46, col)
            row = VGroup(lab, val).arrange(RIGHT, buff=0.9)
            group.add(row)
        group.arrange(DOWN, buff=0.85, aligned_edge=LEFT).move_to(ORIGIN)
        if group.width > 12:
            group.scale_to_fit_width(12)

        for r in group:
            self.play(FadeIn(r[0]), run_time=0.6)
            self.wait(0.7)
            self.play(FadeIn(r[1]), run_time=0.6)
            self.wait(HOLD)
        self.wait(HOLD_SHORT)
        self.clear_all()

        t = self.statement("Nobody is forecasting one June.", 36, hold=HOLD)
        self.swap(t, "We are counting how often each June happens.",
                  36, AMBER, hold=HOLD_LAND)
        self.clear_all()

        t = self.statement("And that is the whole method.", 38, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)
        self.statement("A weighted coin, twenty flips,\nten thousand times.",
                       38, weight=BOLD, hold=HOLD_LAND)
        self.clear_all()
