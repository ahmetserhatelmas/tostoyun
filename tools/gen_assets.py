#!/usr/bin/env python3
"""Generate placeholder sprites and short SFX for Tostçu."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "sprites"
SFX = ROOT / "assets" / "sfx"
UI = ROOT / "assets" / "ui"

PALETTE = {
    "cream": (244, 228, 193),
    "wood": (139, 90, 43),
    "dark": (61, 43, 31),
    "bread": (222, 184, 122),
    "toast": (196, 140, 74),
    "crust": (166, 108, 52),
    "cheese": (244, 208, 63),
    "sucuk": (139, 30, 30),
    "ketchup": (192, 57, 43),
    "ayran": (245, 245, 240),
    "grill": (70, 55, 45),
    "leaf": (80, 140, 70),
    "sky": (168, 210, 230),
    "white": (255, 255, 255),
    "outline": (48, 32, 22),
}


def new_img(size: int, color=(0, 0, 0, 0)) -> Image.Image:
    return Image.new("RGBA", (size, size), color)


def circle(draw: ImageDraw.ImageDraw, xy, fill, outline=None, width=4):
    draw.ellipse(xy, fill=fill, outline=outline or PALETTE["outline"], width=width)


def rounded(draw: ImageDraw.ImageDraw, xy, fill, radius=18, outline=None, width=4):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline or PALETTE["outline"], width=width)


def save(img: Image.Image, name: str, folder=SPRITES):
    path = folder / f"{name}.png"
    img.save(path)
    print("wrote", path.relative_to(ROOT))


def icon_bg(size, fill):
    img = new_img(size)
    d = ImageDraw.Draw(img)
    pad = 6
    rounded(d, [pad, pad, size - pad, size - pad], fill, radius=size // 5)
    return img, d


def draw_bread(d, cx, cy, w, h, toasted=False):
    fill = PALETTE["toast"] if toasted else PALETTE["bread"]
    rounded(d, [cx - w, cy - h, cx + w, cy + h], fill, radius=h // 2)
    if toasted:
        for i, xoff in enumerate((-w // 2, 0, w // 2)):
            d.line([cx + xoff, cy - h + 14, cx + xoff + 8, cy + h - 14], fill=PALETTE["crust"], width=4)


def make_food_icons():
    s = 128
    # bread
    img, d = icon_bg(s, (250, 236, 210))
    draw_bread(d, 64, 68, 40, 28, False)
    save(img, "bread")

    img, d = icon_bg(s, (250, 236, 210))
    draw_bread(d, 64, 68, 40, 28, True)
    save(img, "toast")

    img, d = icon_bg(s, (255, 244, 180))
    rounded(d, [34, 36, 94, 96], PALETTE["cheese"], radius=8)
    d.ellipse([48, 50, 62, 64], fill=(255, 230, 120), outline=PALETTE["outline"], width=2)
    d.ellipse([70, 68, 82, 80], fill=(255, 230, 120), outline=PALETTE["outline"], width=2)
    save(img, "cheese")

    img, d = icon_bg(s, (255, 220, 214))
    for i, (x, y) in enumerate(((44, 48), (64, 40), (84, 52))):
        circle(d, [x - 16, y - 12, x + 16, y + 20], PALETTE["sucuk"], width=3)
        d.ellipse([x - 4, y - 2, x + 4, y + 6], fill=(90, 20, 20))
    save(img, "sucuk")

    img, d = icon_bg(s, (255, 228, 224))
    rounded(d, [50, 28, 78, 86], PALETTE["ketchup"], radius=10)
    rounded(d, [56, 18, 72, 34], (220, 80, 70), radius=6)
    d.polygon([(64, 86), (56, 104), (72, 104)], fill=PALETTE["ketchup"], outline=PALETTE["outline"])
    save(img, "ketchup")

    img, d = icon_bg(s, (230, 240, 235))
    rounded(d, [40, 34, 88, 102], PALETTE["ayran"], radius=14)
    d.rectangle([40, 34, 88, 50], fill=(230, 230, 225), outline=PALETTE["outline"], width=3)
    d.ellipse([52, 60, 76, 78], fill=(255, 255, 255), outline=(200, 200, 195), width=2)
    save(img, "ayran")

    def plated(name, extras):
        img, d = icon_bg(s, (235, 245, 235))
        circle(d, [18, 28, 110, 112], (245, 245, 242), width=4)
        draw_bread(d, 64, 70, 36, 22, True)
        extras(d)
        save(img, name)

    plated("sade", lambda d: None)
    plated("kasarli", lambda d: rounded(d, [40, 58, 88, 74], PALETTE["cheese"], radius=6, width=2))
    plated("sucuklu", lambda d: (
        circle(d, [46, 58, 66, 78], PALETTE["sucuk"], width=2),
        circle(d, [64, 56, 84, 76], PALETTE["sucuk"], width=2),
    ))

    def karisik(d):
        rounded(d, [40, 56, 88, 72], PALETTE["cheese"], radius=6, width=2)
        circle(d, [48, 60, 66, 78], PALETTE["sucuk"], width=2)
        d.polygon([(70, 52), (78, 80), (86, 54)], fill=PALETTE["ketchup"])

    plated("karisik", karisik)

    img, d = icon_bg(s, (80, 70, 65))
    draw_bread(d, 64, 68, 40, 28, True)
    overlay = Image.new("RGBA", (s, s), (20, 16, 14, 140))
    img = Image.alpha_composite(img, overlay)
    d = ImageDraw.Draw(img)
    d.line([36, 40, 92, 92], fill=(40, 30, 25), width=6)
    save(img, "burnt")

    img, d = icon_bg(s, (250, 236, 210))
    draw_bread(d, 64, 58, 36, 22, True)
    rounded(d, [40, 48, 88, 64], PALETTE["cheese"], radius=6, width=2)
    save(img, "toast_cheese")

    img, d = icon_bg(s, (250, 236, 210))
    draw_bread(d, 64, 58, 36, 22, True)
    circle(d, [48, 50, 68, 70], PALETTE["sucuk"], width=2)
    circle(d, [64, 52, 84, 72], PALETTE["sucuk"], width=2)
    save(img, "toast_sucuk")

    img, d = icon_bg(s, (250, 236, 210))
    draw_bread(d, 64, 58, 36, 22, True)
    rounded(d, [40, 48, 88, 62], PALETTE["cheese"], radius=6, width=2)
    circle(d, [50, 54, 70, 74], PALETTE["sucuk"], width=2)
    save(img, "toast_mixed")

    img, d = icon_bg(s, (250, 236, 210))
    draw_bread(d, 64, 58, 36, 22, True)
    rounded(d, [40, 48, 88, 62], PALETTE["cheese"], radius=6, width=2)
    circle(d, [50, 54, 70, 74], PALETTE["sucuk"], width=2)
    d.polygon([(74, 44), (82, 72), (90, 46)], fill=PALETTE["ketchup"])
    save(img, "toast_mixed_cooked")


def make_stations():
    s = 160
    img, d = icon_bg(s, (90, 72, 58))
    rounded(d, [28, 40, 132, 128], PALETTE["grill"], radius=16)
    d.line([40, 60, 120, 60], fill=(40, 32, 28), width=5)
    d.line([40, 84, 120, 84], fill=(40, 32, 28), width=5)
    d.line([40, 108, 120, 108], fill=(40, 32, 28), width=5)
    save(img, "toaster")

    img, d = icon_bg(s, (90, 80, 72))
    rounded(d, [48, 36, 112, 70], (70, 70, 75), radius=8)
    rounded(d, [40, 66, 120, 124], (95, 95, 100), radius=12)
    d.line([52, 86, 108, 86], fill=(60, 60, 65), width=4)
    d.line([52, 102, 108, 102], fill=(60, 60, 65), width=4)
    save(img, "trash")


def make_ui_icons():
    s = 96
    img = new_img(s)
    d = ImageDraw.Draw(img)
    d.polygon([(48, 14), (58, 38), (84, 38), (64, 56), (72, 82), (48, 66), (24, 82), (32, 56), (12, 38), (38, 38)], fill=(244, 208, 63), outline=PALETTE["outline"])
    save(img, "star", UI)
    img2 = new_img(s)
    d2 = ImageDraw.Draw(img2)
    d2.polygon([(48, 14), (58, 38), (84, 38), (64, 56), (72, 82), (48, 66), (24, 82), (32, 56), (12, 38), (38, 38)], fill=(200, 190, 170), outline=PALETTE["outline"])
    save(img2, "star_empty", UI)

    img = new_img(s)
    d = ImageDraw.Draw(img)
    d.polygon([(48, 84), (16, 48), (16, 36), (30, 20), (48, 28), (66, 20), (80, 36), (80, 48)], fill=(192, 57, 43), outline=PALETTE["outline"])
    save(img, "heart", UI)

    img = new_img(s)
    d = ImageDraw.Draw(img)
    circle(d, [16, 16, 80, 80], (244, 208, 63))
    d.ellipse([28, 28, 50, 50], fill=(255, 230, 130))
    save(img, "coin", UI)

    img = new_img(s)
    d = ImageDraw.Draw(img)
    circle(d, [18, 18, 78, 78], (255, 255, 255), width=5)
    d.line([48, 30, 48, 52], fill=PALETTE["outline"], width=6)
    d.line([48, 52, 64, 64], fill=PALETTE["outline"], width=6)
    save(img, "clock", UI)


def make_customers():
    variants = [
        ("a", (255, 220, 190), (60, 40, 30), (70, 120, 180)),
        ("b", (232, 190, 150), (30, 20, 15), (192, 80, 70)),
        ("c", (250, 224, 196), (140, 90, 40), (80, 140, 110)),
        ("d", (210, 168, 130), (20, 20, 25), (120, 90, 160)),
    ]
    w, h = 160, 220
    for name, skin, hair, shirt in variants:
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        # body
        rounded(d, [40, 118, 120, 210], shirt, radius=22)
        # arms
        rounded(d, [18, 130, 46, 186], skin, radius=12, width=3)
        rounded(d, [114, 130, 142, 186], skin, radius=12, width=3)
        # head
        circle(d, [42, 36, 118, 122], skin, width=4)
        # hair
        d.pieslice([42, 28, 118, 90], 180, 360, fill=hair, outline=PALETTE["outline"], width=3)
        # eyes
        circle(d, [62, 72, 74, 86], (40, 30, 25), width=1)
        circle(d, [88, 72, 100, 86], (40, 30, 25), width=1)
        # smile
        d.arc([66, 86, 96, 108], 20, 160, fill=(120, 60, 50), width=3)
        save(img, f"customer_{name}")

        angry = img.copy()
        ad = ImageDraw.Draw(angry)
        ad.rectangle([56, 62, 106, 70], fill=(180, 40, 40))
        ad.arc([66, 92, 96, 114], 200, 340, fill=(120, 40, 40), width=3)
        save(angry, f"customer_{name}_angry")


def make_bg_bits():
    img = Image.new("RGBA", (720, 280), (168, 210, 230, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 180, 720, 280], fill=(190, 210, 170))
    d.ellipse([280, 40, 440, 200], fill=(255, 255, 255, 90))
    d.rectangle([80, 90, 200, 200], fill=(210, 180, 140), outline=PALETTE["outline"], width=4)
    d.polygon([(80, 90), (140, 40), (200, 90)], fill=(160, 70, 60), outline=PALETTE["outline"])
    d.rectangle([500, 70, 640, 200], fill=(200, 170, 130), outline=PALETTE["outline"], width=4)
    d.polygon([(500, 70), (570, 20), (640, 70)], fill=(90, 120, 90), outline=PALETTE["outline"])
    save(img, "window")

    icon = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(icon)
    rounded(d, [36, 36, 476, 476], (244, 228, 193), radius=90)
    draw_bread(d, 256, 270, 150, 90, True)
    rounded(d, [150, 230, 362, 290], PALETTE["cheese"], radius=16, width=6)
    circle(d, [190, 250, 250, 310], PALETTE["sucuk"], width=5)
    icon.save(ROOT / "icon.png")
    print("wrote icon.png")


def write_wav(path: Path, samples, rate=22050):
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s)))) for s in samples)
        w.writeframes(frames)
    print("wrote", path.relative_to(ROOT))


def tone(freq, dur, vol=0.35, rate=22050, fn=math.sin):
    n = int(rate * dur)
    out = []
    for i in range(n):
        t = i / rate
        env = min(1.0, i / 180.0) * min(1.0, (n - i) / 400.0)
        out.append(vol * env * 32767 * fn(2 * math.pi * freq * t))
    return out


def sweep(f0, f1, dur, vol=0.3):
    n = int(22050 * dur)
    out = []
    for i in range(n):
        t = i / 22050
        freq = f0 + (f1 - f0) * (i / max(1, n - 1))
        env = min(1.0, i / 150.0) * min(1.0, (n - i) / 350.0)
        out.append(vol * env * 32767 * math.sin(2 * math.pi * freq * t))
    return out


def make_sfx():
    write_wav(SFX / "tap.wav", tone(520, 0.07, 0.25))
    write_wav(SFX / "cook.wav", sweep(180, 320, 0.18, 0.22))
    write_wav(SFX / "ding.wav", tone(880, 0.16, 0.28) + tone(1175, 0.18, 0.22))
    write_wav(SFX / "take.wav", sweep(400, 700, 0.1, 0.22))
    write_wav(SFX / "coin.wav", tone(988, 0.08, 0.25) + tone(1318, 0.12, 0.22))
    write_wav(SFX / "angry.wav", sweep(220, 90, 0.28, 0.3))
    write_wav(SFX / "burn.wav", sweep(140, 60, 0.35, 0.28))
    write_wav(SFX / "trash.wav", tone(140, 0.12, 0.2, fn=lambda x: 1 if math.sin(x) > 0 else -1))
    write_wav(SFX / "wrong.wav", tone(180, 0.16, 0.28))
    write_wav(SFX / "win.wav", tone(523, 0.12) + tone(659, 0.12) + tone(784, 0.2))
    write_wav(SFX / "lose.wav", tone(330, 0.16) + tone(247, 0.22))


def main():
    SPRITES.mkdir(parents=True, exist_ok=True)
    SFX.mkdir(parents=True, exist_ok=True)
    UI.mkdir(parents=True, exist_ok=True)
    make_food_icons()
    make_stations()
    make_ui_icons()
    make_customers()
    make_bg_bits()
    make_sfx()


if __name__ == "__main__":
    main()
