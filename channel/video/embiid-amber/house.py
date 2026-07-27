"""House scene kit — shared style for every scene in the video.

Everything visual derives from here so forty scenes look like one film.
This is the theme module referenced in the animate skill: build it once,
every future video is cheaper.

Pacing rules enforced by the helpers (see animate/references/pacing.md):
  * one new idea per beat
  * never animate and explain at the same time
  * every beat ends in stillness
  * max ~8 words on screen
"""

from manim import *

# ---------------------------------------------------------------- palette
GROUND = "#0d1411"
BONE = "#eef2ec"
DIM = "#8a9c94"
GRID = "#3b4a43"
GHOST = "#5d6f67"
AMBER = "#d99a2b"      # played hurt — the load-bearing colour
RED = "#c9503a"        # missed entirely
CLAY = "#e4714f"       # rules, emphasis
COOL = "#5aa87d"       # the correction / the honest number

FONT = "DejaVu Sans"
config.background_color = GROUND

# Beat lengths. Named so pacing is a decision, not an accident.
HOLD_SHORT = 1.6
HOLD = 2.2
HOLD_LONG = 2.8
HOLD_LAND = 3.2


def txt(s, size=32, color=BONE, weight=NORMAL):
    return Text(s, font=FONT, font_size=size, color=color, weight=weight)


def num(s, size=150, color=BONE):
    return Text(s, font=FONT, font_size=size, color=color, weight=BOLD)


class HouseScene(Scene):
    """Base with the beat helpers every scene uses."""

    def kicker(self, s):
        """Small uppercase label, top-left. Orients without explaining."""
        k = txt(s.upper(), 22, DIM).to_corner(UL, buff=0.7)
        self.play(FadeIn(k), run_time=0.6)
        return k

    def statement(self, s, size=38, color=BONE, hold=HOLD_LONG, weight=NORMAL):
        """A line, alone, centred. The workhorse beat."""
        t = txt(s, size, color, weight).move_to(ORIGIN)
        if t.width > 12:
            t.scale_to_fit_width(12)
        self.play(FadeIn(t, shift=UP * 0.15), run_time=0.8)
        self.wait(hold)
        return t

    def swap(self, old, s, size=38, color=BONE, hold=HOLD_LONG):
        """Replace a line with the next one. One idea at a time."""
        t = txt(s, size, color).move_to(old)
        if t.width > 12:
            t.scale_to_fit_width(12)
        self.play(FadeOut(old), run_time=0.45)
        self.play(FadeIn(t), run_time=0.7)
        self.wait(hold)
        return t

    def clear_all(self, run_time=0.9):
        if self.mobjects:
            self.play(*[FadeOut(m) for m in self.mobjects], run_time=run_time)
        self.wait(0.4)

    def bignum(self, value, caption, color=BONE, hold=HOLD_LONG):
        n = num(value, 150, color)
        c = txt(caption, 30, DIM).next_to(n, DOWN, buff=0.4)
        g = VGroup(n, c).move_to(ORIGIN)
        if g.width > 12:
            g.scale_to_fit_width(12)
        self.play(FadeIn(n, shift=UP * 0.2), run_time=0.9)
        self.play(FadeIn(c), run_time=0.6)
        self.wait(hold)
        return g


def games_grid(healthy=14, hurt=52, missed=12, cols=13, side=0.34):
    """The 78 playoff games. The spine of the whole film."""
    total = healthy + hurt + missed
    g = VGroup(*[
        Square(side_length=side, fill_opacity=1, fill_color=GRID,
               stroke_width=0)
        for _ in range(total)
    ])
    g.arrange_in_grid(rows=6, cols=cols, buff=0.14)
    return g


def paint(grid, healthy=14, hurt=52):
    """Return the three sub-groups in canonical order."""
    return (VGroup(*grid[:healthy]),
            VGroup(*grid[healthy:healthy + hurt]),
            VGroup(*grid[healthy + hurt:]))


def bar(width, height=0.5, color=AMBER):
    return Rectangle(width=max(width, 0.001), height=height,
                     fill_opacity=1, fill_color=color, stroke_width=0)
