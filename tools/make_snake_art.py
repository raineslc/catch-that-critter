"""Draws the hidden snakes' art (CC0, made for this project): a 2-frame 16x16 slither strip for
the map and pen, and a 38x38 portrait (19x19 drawn at 2x) like the pack's facesets.
Run: python tools/make_snake_art.py  -> writes assets/sprites/animals/<snake>/sprite_sheet.png, faceset.png"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from make_food_icons import PALETTE, png  # noqa: E402

# Green vine snake colors on top of the shared palette.
VINE = dict(PALETTE, **{
    "G": (112, 196, 64), "g": (60, 132, 44), "L": (206, 232, 120),
    "e": (40, 30, 20), "r": (220, 64, 52), "D": (22, 26, 24),
})

SNAKES = {
    "green_vine_snake": {
        "palette": VINE,
        "frames": [
            [
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "...........kkkk.",
                "..........kGGGGk",
                "..kkkk...kGGeGGk",
                ".kGGGGk.kGGLLLkk",
                "kGgkkGGkGGgk.kr.",
                "kgk..kGGGgk...r.",
                ".k....kLLk......",
                ".......kk.......",
                "................",
                "................",
            ],
            [
                "................",
                "................",
                "................",
                "................",
                "................",
                "................",
                "...........kkkk.",
                "..........kGGGGk",
                "..........kGeGGk",
                ".kk.....kkGLLLkk",
                "kGGk...kGGGk..r.",
                "kgGGkkkGGgk...r.",
                ".kgGGGGLLk......",
                "..kkkkkkk.......",
                "................",
                "................",
            ],
        ],
        "face": [
            "DDDDDDDDDDDDDDDDDDD",
            "DDDDDDDDDDDDDDDDDDD",
            "DDDDDDDkkkkkkDDDDDD",
            "DDDDDkkGGGGGGkkDDDD",
            "DDDDkGGGGGGGGGGkDDD",
            "DDDkGGkkkGGGGGGGkDD",
            "DDkGGkHHekGGGGGGGkD",
            "DDkGGkHeekGGGGGGGkD",
            "DkGGGGkkkGGGGgGGGkD",
            "DkGGGGGGGGGGgGGGGkD",
            "kLLLGGGGGGGGGGGGGkD",
            "kkLLLLLGGGGGGGGGkDD",
            "rkkkkLLLLLLGGGGkDDD",
            "DrDDDkkkkkLLLLkDDDD",
            "rDDDDDDDDkGGGGkDDDD",
            "DDDDDDDDDkGgGGkDDDD",
            "DDDDDDDDkGGGgGGkDDD",
            "DDDDDDDDkGGGGGGkDDD",
            "DDDDDDDDDDDDDDDDDDD",
        ],
    },
}


if __name__ == "__main__":
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/sprites/animals")
    for name, art in SNAKES.items():
        out = root / name
        out.mkdir(parents=True, exist_ok=True)
        strip = [a + b for a, b in zip(*art["frames"])]
        (out / "sprite_sheet.png").write_bytes(png(strip, 1, art["palette"]))
        (out / "faceset.png").write_bytes(png(art["face"], 2, art["palette"]))
        print("wrote", out)
