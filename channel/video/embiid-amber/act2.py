"""ACT 2 — Myth one: seven-footers break.

Verdict: unresolved, leaning weaker than the folklore. The belief is not
supported by the peer-reviewed record, the single best-powered study points
the other way, and the vivid version of it -- the big-man foot injury --
does not concentrate in big men in the league's own medical data.

Every figure here is sourced. See scripts/amber.md for citations.
"""

from manim import *
from house import *


class A2_Belief(HouseScene):
    """The belief, at full strength, with the graveyard of names."""

    def construct(self):
        k = self.kicker("Myth one · seven-footers break")
        self.wait(0.6)

        t = self.statement("Big men are made of glass.", 42, hold=HOLD)
        t = self.swap(t, "It is the oldest scouting instinct in basketball.",
                      34, DIM, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        names = ["Bill Walton", "Sam Bowie", "Yao Ming",
                 "Greg Oden", "Joel Embiid"]
        col = VGroup(*[txt(n, 36, BONE) for n in names])
        col.arrange(DOWN, buff=0.45).move_to(ORIGIN)
        for n in col:
            self.play(FadeIn(n), run_time=0.5)
            self.wait(0.65)
        self.wait(HOLD)

        cap = txt("And there is a graveyard of names behind it.",
                  30, DIM).next_to(col, DOWN, buff=0.8)
        self.play(FadeIn(cap), run_time=0.7)
        self.wait(HOLD_LONG)
        self.clear_all()


class A2_TheOrigin(HouseScene):
    """Where the belief actually comes from. Give it its best hearing."""

    def construct(self):
        k = self.kicker("Where the number comes from")
        self.wait(0.6)

        t = self.statement("2014. FiveThirtyEight.", 36, DIM, hold=HOLD_SHORT)
        t = self.swap(t, "Every lottery pick since 2000,", 34, hold=HOLD_SHORT)
        t = self.swap(t, "sorted by height.", 34, hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        rows = [("6′8″ and under", "13.5%", 13.5, BONE),
                ("6′9″ and up", "17.9%", 17.9, AMBER),
                ("7′0″ and up", "24%", 24.0, CLAY)]

        # Labels right-aligned in a fixed gutter so the bars share a baseline.
        group = VGroup()
        for name, pct, val, col in rows:
            lab = txt(name, 27, DIM)
            b = bar(val * 0.28, 0.5, col)
            n = txt(pct, 30, col)
            lab.move_to(LEFT * 4.4, aligned_edge=RIGHT)
            b.next_to(lab, RIGHT, buff=0.5).align_to(lab, DOWN)
            n.next_to(b, RIGHT, buff=0.35)
            group.add(VGroup(lab, b, n))
        group.arrange(DOWN, buff=0.65, aligned_edge=LEFT).move_to(UP * 0.5)

        head = txt("share of potential games missed", 25,
                   DIM).next_to(group, UP, buff=0.7)
        self.play(FadeIn(head), run_time=0.6)
        for r in group:
            self.play(FadeIn(r[0]), GrowFromEdge(r[1], LEFT), run_time=0.8)
            self.play(FadeIn(r[2]), run_time=0.4)
            self.wait(0.9)
        self.wait(HOLD_LONG)

        cap = txt("A clean gradient. Taller, more missed.",
                  32, BONE).next_to(group, DOWN, buff=0.9)
        self.play(FadeIn(cap), run_time=0.8)
        self.wait(HOLD_LONG)
        self.clear_all()


class A2_Physics(HouseScene):
    """The mechanism, given a real hearing. The physics is not in dispute."""

    def construct(self):
        k = self.kicker("And the physics agrees")
        self.wait(0.6)

        t = self.statement("Double a body's height.", 38, hold=HOLD_SHORT)
        self.play(FadeOut(t), run_time=0.45)

        a = txt("mass", 30, DIM).move_to(LEFT * 3.4 + UP * 0.9)
        a2 = txt("×8", 66, BONE).next_to(a, DOWN, buff=0.35)
        self.play(FadeIn(VGroup(a, a2)), run_time=0.8)
        self.wait(HOLD_SHORT)

        b = txt("bone cross-section", 30, DIM).move_to(RIGHT * 2.0 + UP * 0.9)
        b2 = txt("×4", 66, BONE).next_to(b, DOWN, buff=0.35)
        self.play(FadeIn(VGroup(b, b2)), run_time=0.8)
        self.wait(HOLD)

        res = txt("Twice the stress through the same bone.",
                  34, AMBER).move_to(DOWN * 1.9)
        self.play(FadeIn(res), run_time=0.8)
        self.wait(HOLD_LONG)
        self.clear_all()

        t = self.statement("A private lab that has tested six hundred NBA players",
                           32, DIM, hold=HOLD_SHORT)
        t = self.swap(t, "found the tallest produce about 15 percent less",
                      34, hold=HOLD_SHORT)
        t = self.swap(t, "braking force, pound for pound.", 34, hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        self.statement("An Escalade with a Honda brake.", 40, AMBER,
                       hold=HOLD_LAND)
        self.clear_all()

        self.statement("So the belief has a mechanism.\nIt should be easy to confirm.",
                       36, DIM, hold=HOLD_LONG)
        self.clear_all()


class A2_TheLiterature(HouseScene):
    """The turn. The peer-reviewed record doesn't cooperate."""

    def construct(self):
        k = self.kicker("The peer-reviewed record")
        self.wait(0.6)

        t = self.statement("It is not.", 42, weight=BOLD, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("The largest direct test of height in the NBA:",
                           32, DIM, hold=HOLD_SHORT)
        self.play(FadeOut(t), run_time=0.45)

        stats = VGroup(
            VGroup(txt("627", 54, BONE), txt("players", 26, DIM)).arrange(DOWN, buff=0.2),
            VGroup(txt("73,209", 54, BONE), txt("games", 26, DIM)).arrange(DOWN, buff=0.2),
            VGroup(txt("1,663", 54, BONE), txt("injuries", 26, DIM)).arrange(DOWN, buff=0.2),
        ).arrange(RIGHT, buff=1.3).move_to(UP * 0.6)
        for s in stats:
            self.play(FadeIn(s), run_time=0.55)
            self.wait(0.5)
        self.wait(HOLD)

        find = txt("Injury odds rose 10.6 percent", 34,
                   BONE).next_to(stats, DOWN, buff=1.0)
        self.play(FadeIn(find), run_time=0.8)
        self.wait(HOLD_SHORT)
        find2 = txt("for every six centimetres of height  —  lost.",
                    34, COOL).next_to(find, DOWN, buff=0.35)
        self.play(FadeIn(find2), run_time=0.8)
        self.wait(HOLD_LAND)
        self.clear_all()

        t = self.statement("The shorter players got hurt more.", 40,
                           weight=BOLD, hold=HOLD_LAND)
        self.play(FadeOut(t), run_time=0.5)

        # The pile-on.
        k2 = self.kicker("And it is not one study")
        studies = [
            "1,094 players, 17 seasons — demographics not correlated",
            "1,153 ankle and knee injuries — height, no association",
            "238 season-ending injuries — minutes, not anthropometrics",
        ]
        col = VGroup(*[txt(s, 28, DIM) for s in studies])
        col.arrange(DOWN, buff=0.55, aligned_edge=LEFT).move_to(ORIGIN)
        if col.width > 12:
            col.scale_to_fit_width(12)
        for s in col:
            self.play(FadeIn(s), run_time=0.6)
            self.wait(1.0)
        self.wait(HOLD_LONG)
        self.clear_all()


class A2_TheFoot(HouseScene):
    """The sharpest finding: the big-man foot injury isn't a big-man injury."""

    def construct(self):
        k = self.kicker("The vivid version")
        self.wait(0.6)

        t = self.statement("The navicular fracture.", 40, hold=HOLD_SHORT)
        t = self.swap(t, "The bone that ended Bill Walton.", 34, DIM,
                      hold=HOLD_SHORT)
        t = self.swap(t, "The one Embiid broke before he ever played a game.",
                      34, DIM, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("The league went looking in its own medical records.",
                           34, hold=HOLD_SHORT)
        t = self.swap(t, "Every lower-body stress fracture. Six seasons.",
                      34, DIM, hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        a = VGroup(txt("22", 96, BONE), txt("stress fractures", 27, DIM)
                   ).arrange(DOWN, buff=0.25).move_to(LEFT * 2.8)
        b = VGroup(txt("17", 96, AMBER), txt("of them in the foot", 27, DIM)
                   ).arrange(DOWN, buff=0.25).move_to(RIGHT * 2.8)
        self.play(FadeIn(a), run_time=0.8)
        self.wait(HOLD_SHORT)
        self.play(FadeIn(b), run_time=0.8)
        self.wait(HOLD)
        self.clear_all()

        self.statement("Distributed evenly across positions.", 40, COOL,
                       hold=HOLD_LAND, weight=BOLD)
        self.clear_all()

        t = self.statement("The signature big-man injury", 36, hold=HOLD_SHORT)
        self.swap(t, "is not concentrated in big men.", 38, COOL, hold=HOLD_LAND)
        self.clear_all()

        # Availability bias, named.
        t = self.statement("Zydrunas Ilgauskas was seven foot three.", 36,
                           hold=HOLD_SHORT)
        t = self.swap(t, "He broke the same bone.", 36, hold=HOLD_SHORT)
        t = self.swap(t, "Then played nine more seasons.", 36, COOL, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        self.statement("You remember Walton and Yao.\nYou do not remember Ilgauskas.",
                       36, hold=HOLD_LAND)
        self.clear_all()


class A2_Verdict(HouseScene):
    """Why the two literatures disagree, and the honest verdict."""

    def construct(self):
        k = self.kicker("So why do the numbers disagree?")
        self.wait(0.6)

        t = self.statement("Games missed is not the same as getting hurt.",
                           36, hold=HOLD_LONG)
        t = self.swap(t, "Height may not change how often you break.", 34, DIM,
                      hold=HOLD)
        t = self.swap(t, "It may change how long you are gone.", 34, AMBER,
                      hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("A sprained ankle costs days.", 32, DIM,
                           hold=HOLD_SHORT)
        t = self.swap(t, "A navicular fracture costs thirty-seven games.",
                      34, AMBER, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("And nobody has cleanly tested that.", 36,
                           hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        # The selection effect — lands on Embiid himself.
        k2 = self.kicker("And one more thing")
        t = self.statement("Tall lottery picks are drafted on projection.",
                           34, hold=HOLD_SHORT)
        t = self.swap(t, "Short ones are drafted on what they have already done.",
                      34, hold=HOLD)
        t = self.swap(t, "Teams accept medical risk to get size.", 34, DIM,
                      hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        self.statement("Joel Embiid was drafted third\nwith a broken navicular.",
                       38, AMBER, hold=HOLD_LAND, weight=BOLD)
        self.clear_all()

        t = self.statement("That is the selection effect, wearing a jersey.",
                           34, DIM, hold=HOLD_LONG)
        self.play(FadeOut(t), run_time=0.5)

        # Verdict.
        t = self.statement("So: do seven-footers break more?", 38, hold=HOLD)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("The honest answer is that nobody knows.", 40,
                           weight=BOLD, hold=HOLD_LONG)
        t = self.swap(t, "There have never been enough of them to find out.",
                      34, DIM, hold=HOLD_LAND)
        self.play(FadeOut(t), run_time=0.5)

        t = self.statement("What does predict injury, in every study:",
                           32, DIM, hold=HOLD_SHORT)
        self.play(FadeOut(t), run_time=0.45)

        items = ["prior injury", "minutes played", "usage", "age"]
        col = VGroup(*[txt(s, 38, BONE) for s in items])
        col.arrange(DOWN, buff=0.42).move_to(UP * 0.3)
        for s in col:
            self.play(FadeIn(s), run_time=0.5)
            self.wait(0.6)
        self.wait(HOLD)

        cap = txt("Not height.", 36, COOL).next_to(col, DOWN, buff=0.8)
        self.play(FadeIn(cap), run_time=0.8)
        self.wait(HOLD_LAND)
        self.clear_all()
