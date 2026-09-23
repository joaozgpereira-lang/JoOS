#!/usr/bin/env python3
"""JoOS wallpaper generator — pure-Python (no dependencies).

Produces pixel-art wallpapers (Kingdom: New Lands style) for each JoOS theme
using only the standard library (struct + zlib to write PNG). Runs at dev
time and in CI; output lands in
configs/releng/airootfs/usr/share/joos/wallpapers/ so the ISO ships with them.

Usage:  python3 tools/gen-wallpapers.py [output_dir]
"""

import os
import random
import struct
import sys
import zlib

W, H = 1920, 1080
OUT_DEFAULT = "configs/releng/airootfs/usr/share/joos/wallpapers"


def lerp(c1, c2, t):
    t = max(0.0, min(1.0, t))
    return (int(c1[0] + (c2[0] - c1[0]) * t), int(c1[1] + (c2[1] - c1[1]) * t), int(c1[2] + (c2[2] - c1[2]) * t))


def chunk(tag, data):
    c = struct.pack(">I", len(data)) + tag + data
    c += struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    return c


def write_png(path, pixels):
    """pixels: list of rows, each a list of (r,g,b) tuples."""
    raw = bytearray()
    for row in pixels:
        raw.append(0)  # filter type none
        for r, g, b in row:
            raw += bytes((r, g, b))
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 6))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


class Canvas:
    def __init__(self, w, h):
        self.w = w
        self.h = h
        self.px = [[(0, 0, 0)] * w for _ in range(h)]

    def rect(self, x0, y0, x1, y1, color):
        x0, x1 = max(0, int(x0)), min(self.w, int(x1))
        y0, y1 = max(0, int(y0)), min(self.h, int(y1))
        for y in range(y0, y1):
            for x in range(x0, x1):
                self.px[y][x] = color

    def block(self, x, y, size, color):
        self.rect(x, y, x + size, y + size, color)

    def dither_band(self, x0, y0, w, h, c1, c2, block, rng):
        for y in range(y0, y0 + h, block):
            t = (y - y0) / max(1, h)
            for x in range(x0, x0 + w, block):
                d = rng.random()
                c = lerp(c1, c2, t) if d > 0.5 else lerp(c1, c2, min(1.0, t + 0.14))
                self.block(x, y, block, c)

    def disc(self, cx, cy, radius, color):
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if dx * dx + dy * dy <= radius * radius:
                    x, y = cx + dx, cy + dy
                    if 0 <= x < self.w and 0 <= y < self.h:
                        self.px[y][x] = color


def draw_island(cv, cx, base_y, scale, rng, col):
    w = int(90 * scale)
    h = int(14 * scale)
    cv.rect(cx - w // 2, base_y, cx + w // 2, base_y + h, col)
    for _ in range(int(3.5 * scale)):
        tx = cx + rng.randint(-w // 2 + 10, w // 2 - 10)
        th = rng.randint(18, 34) * scale
        cv.rect(tx, base_y - th, tx + 3, base_y, col)
    cv.rect(cx - w // 2 + 6, base_y - int(6 * scale), cx + w // 2 - 6, base_y, lerp(col, (0, 0, 0), 0.15))


def draw_flag(cv, cx, base_y, pole, flag):
    cv.rect(cx, base_y - 60, cx + 4, base_y, pole)
    cv.rect(cx + 4, base_y - 60, cx + 26, base_y - 46, flag)


def gen_theme(name, colors, seed):
    bg_top, bg_mid, bg_bot, sea_deep, sea_mid, sea_surf, sun, flag_c, pole = colors
    rng = random.Random(seed)
    cv = Canvas(W, H)

    sea_y = int(H * 0.56)
    # Sky
    cv.dither_band(0, 0, W, int(H * 0.42), bg_top, bg_mid, 3, rng)
    cv.dither_band(0, int(H * 0.42), W, int(H * 0.14), bg_mid, bg_bot, 3, rng)

    # Sun/Moon disc
    sx, sy = int(W * 0.24), int(H * 0.44)
    for r in (54, 45, 36, 27, 18, 9):
        cv.disc(sx, sy, r, lerp(bg_bot, sun, 1 - r / 60))

    # Clouds
    for cy, cseeds, cw in ((int(H * 0.18), 11, W), (int(H * 0.30), 23, W), (int(H * 0.05), 5, int(W * 0.8))):
        rngc = random.Random(cseeds)
        x = -50
        while x < cw:
            cl = rngc.randint(40, 110)
            cv.rect(x, cy, x + cl, cy + 2, lerp(bg_mid, bg_bot, 0.55))
            cv.rect(x + cl // 3, cy - 2, x + cl - cl // 4, cy, lerp(bg_mid, bg_bot, 0.55))
            x += cl + rngc.randint(45, 80)

    # Sea
    cv.dither_band(0, sea_y, W, H - sea_y, sea_deep, sea_surf, 4, rng)
    for wy in range(sea_y + 8, H, 26):
        wx = 0
        while wx < W:
            cv.rect(wx, wy, wx + 6, wy + 1, lerp(sea_mid, sea_surf, 0.7))
            wx += rng.randint(30, 70)

    # Distant islands
    draw_island(cv, int(W * 0.74), sea_y - 6, 1.1, rng, lerp(bg_bot, sea_deep, 0.6))
    draw_island(cv, int(W * 0.82), sea_y - 2, 0.7, rng, lerp(bg_bot, sea_deep, 0.55))

    # Foreground island with castle flag
    draw_island(cv, int(W * 0.62), H - 88, 2.0, rng, bg_bot)
    draw_flag(cv, int(W * 0.65), H - 88, pole, flag_c)

    # Light column on water
    for yy in range(0, 40, 6):
        width = 14 + yy // 8
        cv.rect(sx - width, sea_y + yy, sx + width, sea_y + yy + 3, lerp(sun, sea_surf, 0.55))

    # Pixel frame
    for b in range(4):
        cv.rect(b, b, W - b, H - b, pole)

    return cv.px


THEMES = {
    "kingdom": dict(
        colors=((11, 14, 20), (26, 31, 46), (44, 50, 68), (20, 26, 38),
                (34, 44, 60), (70, 84, 100), (216, 166, 87), (216, 166, 87), (11, 14, 20)),
        seed=7,
    ),
    "kingdom-dawn": dict(
        colors=((26, 22, 38), (56, 46, 82), (96, 72, 106), (44, 40, 62),
                (82, 78, 110), (140, 120, 150), (232, 180, 180), (232, 180, 180), (26, 22, 38)),
        seed=13,
    ),
    "kingdom-dusk": dict(
        colors=((20, 16, 30), (44, 34, 60), (88, 58, 86), (34, 28, 48),
                (70, 60, 96), (124, 92, 116), (224, 145, 122), (224, 145, 122), (20, 16, 30)),
        seed=29,
    ),
    "ember": dict(
        colors=((23, 16, 13), (48, 30, 20), (92, 50, 30), (30, 22, 18),
                (56, 40, 30), (110, 80, 58), (228, 87, 46), (228, 87, 46), (23, 16, 13)),
        seed=41,
    ),
    "void": dict(
        colors=((6, 7, 9), (12, 14, 18), (22, 26, 32), (12, 16, 14),
                (24, 32, 26), (52, 70, 58), (61, 214, 140), (61, 214, 140), (6, 7, 9)),
        seed=53,
    ),
}


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else OUT_DEFAULT
    os.makedirs(out, exist_ok=True)
    for name, spec in THEMES.items():
        path = os.path.join(out, f"{name}.png")
        write_png(path, gen_theme(name, spec["colors"], spec["seed"]))
        print(f"gerado: {path}")


if __name__ == "__main__":
    main()