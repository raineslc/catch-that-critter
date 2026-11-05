"""Loganator, the 3-year-old's sidekick (the big brother): Henrito's pack art recolored with
brown hair and a green ranger shirt. Red pixels touching skin are skin shadow, not hair.
Run: python tools/make_loganator_art.py  -> writes assets/sprites/sidekicks/loganator/"""
from pathlib import Path

from PIL import Image

SRC = Path("assets/sprites/sidekicks/henrito")
OUT = Path("assets/sprites/sidekicks/loganator")
SKIN, HAIR = (239, 145, 79), (209, 75, 52)
SWAP = {
    (209, 75, 52): (124, 78, 46),     # hair
    (150, 83, 64): (82, 50, 32),      # hair shade
    (242, 234, 241): (110, 156, 92),  # shirt (portrait)
    (227, 241, 245): (110, 156, 92),  # shirt (walking sprite)
    (211, 162, 192): (70, 108, 62),   # shirt shade
}


SHIRT = {(242, 234, 241), (227, 241, 245), (211, 162, 192)}  # also the teeth and mouth, so only below the face


def recolor(image: Image.Image, shirt_from: int, frame: int) -> Image.Image:
    src = image.convert("RGBA")
    out = src.copy()
    px, po = src.load(), out.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            color = (r, g, b)
            near_skin = any(
                0 <= x + dx < src.width and 0 <= y + dy < src.height and px[x + dx, y + dy][:3] == SKIN
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if color == HAIR and near_skin:
                continue  # skin shadow stays
            if color in SHIRT and y % frame < shirt_from:
                continue
            if color in SWAP:
                po[x, y] = SWAP[color] + (a,)
    return out


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    # (file, first shirt row inside each frame, frame height)
    for name, shirt_from, frame in (("sprite_sheet.png", 9, 16), ("faceset.png", 27, 38)):
        recolor(Image.open(SRC / name), shirt_from, frame).save(OUT / name)
        print("wrote", OUT / name)
