"""Draws the 16x16 food icons the art pack doesn't have (CC0, made for this project).
Run: python tools/make_food_icons.py  -> writes assets/ui/food/<name>.png"""
import struct, sys, zlib
from pathlib import Path

PALETTE = {
    ".": None, "k": (26, 20, 16),
    "Y": (250, 214, 74), "y": (214, 160, 40), "G": (120, 184, 72), "g": (64, 120, 48),
    "C": (120, 76, 44), "c": (160, 108, 60), "N": (214, 150, 86), "n": (172, 112, 60),
    "W": (250, 246, 232), "w": (214, 204, 180), "R": (220, 64, 52), "r": (160, 40, 40),
    "P": (150, 84, 170), "p": (104, 52, 124), "H": (255, 255, 255), "K": (232, 140, 150),
    "B": (90, 70, 60), "b": (60, 48, 40), "S": (236, 214, 190), "s": (196, 166, 140),
}

ICONS = {
    "corn": [
        "................",
        ".......kk.......",
        "......kYYk......",
        ".....kYyYyk.....",
        ".....kyYyYk.....",
        "....kgYyYyGk....",
        "....kgyYyYGk....",
        "...kgGYyYyGgk...",
        "...kgGyYyYGgk...",
        "...kgGYyYyGgk...",
        "...kgGkyYkGgk...",
        "....kgGkkGgk....",
        "....kgGGGGgk....",
        ".....kgGGgk.....",
        "......kkkk......",
        "................",
    ],
    "bugs": [
        "................",
        "..k.........k...",
        "...k..kkk..k....",
        "....kkBBBkk.....",
        "...kBbBBBbBk....",
        ".kkkkkkkkkkkkk..",
        "...kGgkGGkgGk...",
        ".kkkGGkGGkGGkkk.",
        "...kgGkGGkGgk...",
        ".kkkGGkGGkGGkkk.",
        "...kGgkGGkgGk...",
        "....kGGkkGGk....",
        ".....kkkkkk.....",
        "................",
        "................",
        "................",
    ],
    "nuts": [
        "................",
        ".......kk.......",
        "......kCk.......",
        "...kkkkkkkkkk...",
        "..kCcCcCcCcCCk..",
        "..kcCcCcCcCcCk..",
        "...kkkkkkkkkk...",
        "...kNNNNNNNnk...",
        "...kNHNNNNNnk...",
        "...kNNNNNNnnk...",
        "....kNNNNNnk....",
        "....kNNNNnnk....",
        ".....kNNnnk.....",
        "......kkkk......",
        "................",
        "................",
    ],
    "eggs": [
        "................",
        "....kkk.........",
        "...kWWWk........",
        "..kWHWWWk.......",
        "..kWHWWWk..kkk..",
        ".kWWWWWWwkkWWWk.",
        ".kWWWWWWwkWHWWWk",
        ".kWWWWWWwkWHWWWk",
        ".kWWWWWwwkWWWWwk",
        "..kWWWwwkWWWWWwk",
        "...kwwwk.kWWWwwk",
        "....kkk...kwwwk.",
        "...........kkk..",
        "................",
        "................",
        "................",
    ],
    "crab": [
        "................",
        ".kk..........kk.",
        "kRRk........kRRk",
        "kRkRk......kRkRk",
        ".kRRk......kRRk.",
        "..kRk.k..k.kRk..",
        "...kRkHkkHkRk...",
        "...kkRRRRRRkk...",
        "..kRRRRRRRRRRk..",
        ".kRRRRRRRRRRRRk.",
        ".krRRRRRRRRRRrk.",
        "..krrrrrrrrrrk..",
        "..k.kk.kk.kk.k..",
        ".k..k..k..k..k..",
        "................",
        "................",
    ],
    "clams": [
        "................",
        "................",
        "......kkkk......",
        "....kkSSSSkk....",
        "...kSsSSSsSSk...",
        "..kSSsSSSsSSSk..",
        "..kSsSSsSSsSSk..",
        ".kSSsSSsSSsSSSk.",
        ".kSsSSsSSSsSSSk.",
        ".kkkkkkkkkkkkkk.",
        ".ksssssssssssk..",
        "..kssssssssssk..",
        "...kkkkkkkkkk...",
        "................",
        "................",
        "................",
    ],
    "plums": [
        "................",
        "........k.......",
        ".......kgk......",
        "......kGgk......",
        "...kkkkGk.......",
        "..kPPPPkPkkk....",
        ".kPHPPPkPPPPk...",
        ".kPHPPPkPPPPPk..",
        ".kPPPPpkHPPPPk..",
        ".kPPPPpkHPPPPk..",
        "..kPPpkPPPPPpk..",
        "...kkkkPPPPppk..",
        ".......kPPppk...",
        "........kkkk....",
        "................",
        "................",
    ],
    "worms": [
        "................",
        "................",
        "................",
        "................",
        "...kkkk...kkkk..",
        "..kKKKKk.kKKKKk.",
        ".kKKkkKKkKKkkKKk",
        ".kKk..kKKKk.kKbk",
        "kKKk...kkk..kKKk",
        "kKk..........kk.",
        "kKk.............",
        ".kk.............",
        "................",
        "................",
        "................",
        "................",
    ],
    "grapes": [
        "................",
        ".......kk.kk....",
        "......kgkkGGk...",
        "......kgkGGk....",
        "....kkkkkkk.....",
        "...kPHkPHkPk....",
        "...kPPkPPkPk....",
        "..kkkkkkkkkkk...",
        "..kPHkPHkPHkPk..",
        "..kPPkPPkPPkPk..",
        "...kkkkkkkkkk...",
        "....kPHkPHkPk...",
        "....kPPkPPkPk...",
        ".....kkkkkkk....",
        "......kPHk......",
        "......kkkk......",
    ],
    "apples": [
        "................",
        ".......k.kk.....",
        ".......kkGGk....",
        "....kkkCkGk.....",
        "...kRRRkRRkk....",
        "..kRHRRRRRRRk...",
        "..kRHRRRRRRRk...",
        "..kRRRRRRRRrk...",
        "..kRRRRRRRRrk...",
        "...kRRRRRRrk....",
        "....kRkkkRk.....",
        ".....k...k......",
        "................",
        "................",
        "................",
        "................",
    ],
}


def png(rows: list[str], scale: int = 1, palette: dict | None = None) -> bytes:
    """Rows of palette letters (all the same width) -> PNG bytes, each pixel scaled up `scale` times."""
    palette = palette or PALETTE
    width = len(rows[0])
    assert all(len(row) == width for row in rows), "rows must be the same width"
    raw = b""
    for row in rows:
        line = b"".join((bytes(palette[ch] + (255,)) if palette[ch] else b"\x00" * 4) * scale for ch in row)
        raw += (b"\x00" + line) * scale
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    header = struct.pack(">IIBBBBB", width * scale, len(rows) * scale, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/ui/food")
    for name, rows in ICONS.items():
        assert len(rows) == 16 and len(rows[0]) == 16, name
        (out / f"{name}.png").write_bytes(png(rows))
        print("wrote", out / f"{name}.png")
