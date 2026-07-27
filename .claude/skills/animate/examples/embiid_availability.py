"""Embiid availability — POC scene.

Design brief: the previous scenes were too dense to follow. This is the
correction. Rules applied throughout:

  * ONE new idea per beat. Never two things moving at once.
  * Every beat ends with 1.5-2.5s of stillness so the eye can land.
  * Maximum ~8 words on screen at a time.
  * Nothing is explained while something else is animating.

Source: the Embiid availability piece. 78 playoff games across eight
postseasons -- 14 started healthy, 52 started with a disclosed ailment,
12 missed entirely.

Render:
  manim -qm embiid.py Availability      # 720p30, fast
  manim -qh embiid.py Availability      # 1080p60, final
"""

from manim import *

# House palette. Amber is the load-bearing colour -- "one colour doing
# most of the work" is the line from the piece.
GROUND = "#0d1411"
BONE = "#eef2ec"
AMBER = "#d99a2b"
DIM = "#8a9c94"      # captions / de-emphasised text
GRID = "#3b4a43"     # resting grid square
GHOST = "#5d6f67"    # outline of a game he missed
CLAY = "#e4714f"

FONT = "DejaVu Sans"

config.background_color = GROUND

HEALTHY, HURT, MISSED = 14, 52, 12
TOTAL = HEALTHY + HURT + MISSED  # 78
COLS = 13


def label(text, size=30, color=BONE, weight=NORMAL):
    return Text(text, font=FONT, font_size=size, color=color, weight=weight)


class Availability(Scene):
    def construct(self):
        self.beat_title()
        dots = self.beat_grid()
        self.beat_missed(dots)
        self.beat_hurt(dots)
        self.beat_healthy(dots)
        self.beat_kicker(dots)

    # ---- 01 -------------------------------------------------------
    def beat_title(self):
        n = Text("78", font=FONT, font_size=190, color=BONE, weight=BOLD)
        cap = label("playoff games", 34, DIM)
        cap.next_to(n, DOWN, buff=0.35)
        g = VGroup(n, cap).move_to(ORIGIN)

        self.play(FadeIn(n, shift=UP * 0.3), run_time=1.0)
        self.play(FadeIn(cap), run_time=0.7)
        self.wait(1.8)

        sub = label("Eight postseasons.", 30, DIM)
        sub.next_to(g, DOWN, buff=0.7)
        self.play(FadeIn(sub), run_time=0.7)
        self.wait(2.0)
        self.play(FadeOut(VGroup(g, sub)), run_time=0.8)

    # ---- 02 -------------------------------------------------------
    def beat_grid(self):
        dots = VGroup(*[
            Square(side_length=0.34, fill_opacity=1, fill_color=GRID,
                   stroke_width=0).set_z_index(1)
            for _ in range(TOTAL)
        ])
        dots.arrange_in_grid(rows=6, cols=COLS, buff=0.14)
        dots.move_to(ORIGIN)

        self.play(
            LaggedStart(*[FadeIn(d, scale=0.6) for d in dots],
                        lag_ratio=0.012),
            run_time=2.0,
        )
        self.wait(1.6)
        return dots

    # ---- 03 -------------------------------------------------------
    def beat_missed(self, dots):
        # Blocks are contiguous so the proportion reads instantly.
        missed = dots[TOTAL - MISSED:]
        cap = label("12 he missed entirely", 32, BONE)
        cap.next_to(dots, DOWN, buff=0.8)

        self.play(
            *[d.animate.set_fill(GROUND).set_stroke(GHOST, 2) for d in missed],
            run_time=1.0,
        )
        self.play(FadeIn(cap), run_time=0.6)
        self.wait(2.2)
        self.play(FadeOut(cap), run_time=0.5)

    # ---- 04 -------------------------------------------------------
    def beat_hurt(self, dots):
        hurt = dots[HEALTHY:HEALTHY + HURT]
        cap = label("52 he played hurt", 32, BONE)
        cap.next_to(dots, DOWN, buff=0.8)

        self.play(*[d.animate.set_fill(AMBER) for d in hurt], run_time=1.2)
        self.play(FadeIn(cap), run_time=0.6)
        self.wait(2.4)
        self.play(FadeOut(cap), run_time=0.5)

    # ---- 05 -------------------------------------------------------
    def beat_healthy(self, dots):
        healthy = dots[:HEALTHY]
        cap = label("14 he started healthy", 32, BONE)
        cap.next_to(dots, DOWN, buff=0.8)

        self.play(*[d.animate.set_fill(BONE) for d in healthy], run_time=1.0)
        self.play(FadeIn(cap), run_time=0.6)
        self.wait(2.6)
        self.play(FadeOut(cap), run_time=0.5)

    # ---- 06 -------------------------------------------------------
    def beat_kicker(self, dots):
        """The turn. Isolate the 14 and land the finding."""
        healthy = VGroup(*dots[:HEALTHY])
        rest = VGroup(*dots[HEALTHY:])

        self.play(FadeOut(rest), run_time=1.0)
        self.wait(0.6)

        row = healthy.copy()
        row.arrange(RIGHT, buff=0.2).scale(1.25).move_to(UP * 0.9)
        self.play(Transform(healthy, row), run_time=1.4)
        self.wait(1.6)

        one = label("Every one of them came in a first round.", 34)
        one.next_to(row, DOWN, buff=1.0)
        self.play(FadeIn(one), run_time=0.8)
        self.wait(2.6)

        two = label("None of them after Game 4.", 34, AMBER)
        two.move_to(one)
        self.play(FadeOut(one), run_time=0.5)
        self.play(FadeIn(two), run_time=0.8)
        self.wait(2.8)

        self.play(FadeOut(VGroup(healthy, two)), run_time=0.9)
        self.wait(0.4)

        end = label("He has never played a second round healthy.",
                    38, BONE, BOLD)
        end.move_to(ORIGIN)
        self.play(FadeIn(end, shift=UP * 0.2), run_time=1.0)
        self.wait(3.0)

        rule = Line(LEFT * 2.2, RIGHT * 2.2, stroke_width=2, color=CLAY)
        rule.next_to(end, DOWN, buff=0.6)
        self.play(Create(rule), run_time=0.7)
        self.wait(2.2)
        self.play(FadeOut(VGroup(end, rule)), run_time=1.0)
        self.wait(0.5)
