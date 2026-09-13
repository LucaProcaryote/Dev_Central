#!/usr/bin/env python3
"""Draws the Mini-Hospital application icons.

One mark, five glyphs: a teal disc, a ring of beads around it, and the
application's own Material symbol in the middle. The glyph is rendered from
the very font Flutter ships, so the favicon in the browser tab and the badge
drawn inside the application are the same shape rather than two drawings that
drift apart.

    python3 tools/generate_icons.py            # writes into all five repos
    python3 tools/generate_icons.py --out /tmp # writes a preview sheet instead

Needs Pillow, and a Flutter checkout for MaterialIcons-Regular.otf.
"""

from __future__ import annotations

import argparse
import math
import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# The brand. One teal for the whole suite - the applications are told apart by
# their glyph, not by their colour, which is what lets a screenshot of any of
# them read as "the same hospital".
TEAL_LIGHT = (14, 156, 147)  # #0E9C93
TEAL_DEEP = (0, 79, 82)  # #004F52

MATERIAL_FONT_CANDIDATES = (
    "/opt/fl/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf",
    os.path.expanduser("~/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf"),
    "/usr/local/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf",
)

# repo directory -> (glyph codepoint, human name for the log)
APPS = {
    # The portal is the front door, so it gets the hospital itself rather than
    # one department's symbol.
    "my-hospital": (0xF86F, "local_hospital"),
    "EHR": (0xF0804, "medical_information"),
    "ADT": (0xF5B4, "bed"),
    "PHARM": (0xF8B1, "medication"),
    "EAI": (0xF0335, "hub"),
    "Dev_Central": (0xF0354, "monitor_heart"),
}

SS = 4  # supersampling factor; everything is drawn big and shrunk with Lanczos


def material_font_path() -> str:
    for candidate in MATERIAL_FONT_CANDIDATES:
        if os.path.exists(candidate):
            return candidate
    sys.exit(
        "MaterialIcons-Regular.otf not found. Pass a Flutter SDK on one of:\n  "
        + "\n  ".join(MATERIAL_FONT_CANDIDATES)
    )


def teal_disc(size: int) -> Image.Image:
    """A disc filled with a diagonal teal gradient, transparent outside."""
    # The gradient is computed on a small tile and scaled up: a smooth ramp
    # needs no more resolution than that, and it keeps the per-pixel Python
    # loop off the 2048-pixel canvas.
    tile = 64
    gradient = Image.new("RGB", (tile, tile))
    pixels = gradient.load()
    for y in range(tile):
        for x in range(tile):
            t = (x + y) / (2 * (tile - 1))
            pixels[x, y] = tuple(
                round(TEAL_LIGHT[c] + (TEAL_DEEP[c] - TEAL_LIGHT[c]) * t)
                for c in range(3)
            )
    gradient = gradient.resize((size, size), Image.BICUBIC)

    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)

    disc = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    disc.paste(gradient, (0, 0), mask)
    return disc


def badge(size: int, codepoint: int, font_path: str, inset: float = 0.0) -> Image.Image:
    """The full mark at `size` pixels.

    `inset` shrinks the disc inside the canvas, for maskable icons where the
    launcher may crop anything outside the middle 80%.
    """
    canvas = size * SS
    disc_size = round(canvas * (1 - inset))
    offset = (canvas - disc_size) // 2

    image = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    image.alpha_composite(teal_disc(disc_size), (offset, offset))

    draw = ImageDraw.Draw(image)
    centre = canvas / 2
    radius = disc_size / 2

    # The beads: eight of them on a ring just inside the rim, alternating big
    # and small so the ring reads as a rhythm rather than a dotted line.
    ring = radius * 0.80
    for i in range(8):
        angle = math.radians(i * 45 - 90)
        bx = centre + ring * math.cos(angle)
        by = centre + ring * math.sin(angle)
        big = i % 2 == 0
        bead = radius * (0.088 if big else 0.055)
        draw.ellipse(
            (bx - bead, by - bead, bx + bead, by + bead),
            fill=(255, 255, 255, 235 if big else 130),
        )

    # The glyph, optically centred on its own ink rather than on its font box.
    font = ImageFont.truetype(font_path, round(radius * 0.92))
    ch = chr(codepoint)
    left, top, right, bottom = draw.textbbox((0, 0), ch, font=font)
    draw.text(
        (centre - (left + right) / 2, centre - (top + bottom) / 2),
        ch,
        font=font,
        fill=(255, 255, 255, 255),
    )

    return image.resize((size, size), Image.LANCZOS)


def write_app_icons(web_dir: Path, codepoint: int, font_path: str) -> list[str]:
    (web_dir / "icons").mkdir(parents=True, exist_ok=True)
    written = []

    for name, size, inset in (
        ("favicon.png", 32, 0.0),
        ("icons/Icon-192.png", 192, 0.0),
        ("icons/Icon-512.png", 512, 0.0),
        # Maskable icons are cropped to a launcher-chosen shape, so the mark is
        # pulled into the middle 80% and the corners are filled with brand teal
        # instead of being left transparent.
        ("icons/Icon-maskable-192.png", 192, 0.20),
        ("icons/Icon-maskable-512.png", 512, 0.20),
    ):
        mark = badge(size, codepoint, font_path, inset=inset)
        if inset:
            plate = Image.new("RGBA", (size, size), TEAL_DEEP + (255,))
            plate.alpha_composite(mark)
            mark = plate
        mark.save(web_dir / name)
        written.append(name)

    return written


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--workspace",
        default=str(Path(__file__).resolve().parents[2]),
        help="directory holding EHR/ ADT/ PHARM/ EAI/ Dev_Central/",
    )
    parser.add_argument("--out", help="write a single preview sheet here instead")
    args = parser.parse_args()

    font_path = material_font_path()

    if args.out:
        sheet = Image.new("RGBA", (5 * 160, 160), (245, 245, 245, 255))
        for i, (repo, (codepoint, _)) in enumerate(APPS.items()):
            sheet.alpha_composite(badge(128, codepoint, font_path), (i * 160 + 16, 16))
        target = Path(args.out) / "icon-preview.png"
        sheet.save(target)
        print(f"preview -> {target}")
        return 0

    workspace = Path(args.workspace)
    for repo, (codepoint, glyph) in APPS.items():
        web_dir = workspace / repo / "web"
        if not web_dir.is_dir():
            print(f"{repo:<12} skipped, no web/ directory at {web_dir}")
            continue
        written = write_app_icons(web_dir, codepoint, font_path)
        print(f"{repo:<12} {glyph:<22} {len(written)} files")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
