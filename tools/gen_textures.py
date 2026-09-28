#!/usr/bin/env python3
"""Tileable PBR-ish textures for the 3D shop."""

from pathlib import Path
import random

from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "textures"
RNG = random.Random(7)


def noise(size, base, amp=18):
    img = Image.new("RGB", (size, size), base)
    px = img.load()
    for y in range(size):
        for x in range(size):
            j = RNG.randint(-amp, amp)
            px[x, y] = tuple(max(0, min(255, c + j)) for c in base)
    return img.filter(ImageFilter.GaussianBlur(0.6))


def wood(path, base, grain, size=512):
    img = noise(size, base, 10)
    d = ImageDraw.Draw(img, "RGBA")
    for x in range(0, size, 9):
        shade = 0 if RNG.random() > 0.5 else 30
        color = tuple(max(0, min(255, c - 18 - shade)) for c in grain) + (70,)
        d.line([(x + RNG.randint(-2, 2), 0), (x + RNG.randint(-3, 3), size)], fill=color, width=RNG.randint(1, 3))
    img = ImageEnhance.Contrast(img).enhance(1.08)
    img.save(path)


def tiles(path, a, b, size=512, cell=64):
    img = Image.new("RGB", (size, size), a)
    d = ImageDraw.Draw(img)
    for y in range(0, size, cell):
        for x in range(0, size, cell):
            fill = a if ((x // cell) + (y // cell)) % 2 == 0 else b
            inset = 2
            d.rectangle([x + inset, y + inset, x + cell - inset, y + cell - inset], fill=fill)
            d.rectangle([x, y, x + cell, y + cell], outline=(90, 70, 55), width=2)
    img = img.filter(ImageFilter.GaussianBlur(0.4))
    img.save(path)


def plaster(path, base, size=512):
    img = noise(size, base, 14)
    img.save(path)


def metal(path, size=256):
    img = noise(size, (168, 172, 178), 12)
    img = ImageEnhance.Contrast(img).enhance(1.2)
    img.save(path)


def fabric(path, base, size=256):
    img = noise(size, base, 16)
    d = ImageDraw.Draw(img, "RGBA")
    for y in range(0, size, 8):
        d.line([(0, y), (size, y)], fill=(255, 255, 255, 18), width=1)
    img.save(path)


def fallback_window(path):
    img = Image.new("RGB", (1280, 720), (168, 206, 230))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 420, 1280, 720], fill=(186, 168, 130))
    d.ellipse([900, 40, 1100, 240], fill=(255, 220, 140))
    d.rectangle([80, 260, 280, 520], fill=(196, 122, 88))
    d.polygon([(80, 260), (180, 170), (280, 260)], fill=(140, 62, 52))
    d.rectangle([520, 220, 760, 520], fill=(214, 176, 132))
    d.polygon([(520, 220), (640, 120), (760, 220)], fill=(90, 122, 86))
    d.rectangle([980, 280, 1200, 520], fill=(176, 98, 78))
    img = img.filter(ImageFilter.GaussianBlur(0.8))
    img.save(path)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    wood(OUT / "wood_light.png", (186, 132, 78), (150, 96, 52))
    wood(OUT / "wood_dark.png", (96, 62, 38), (72, 44, 26))
    tiles(OUT / "floor_tile.png", (214, 186, 150), (186, 150, 112))
    plaster(OUT / "plaster.png", (236, 220, 196))
    metal(OUT / "metal.png")
    fabric(OUT / "fabric_blue.png", (62, 102, 168))
    fabric(OUT / "fabric_red.png", (168, 58, 52))
    fabric(OUT / "fabric_green.png", (58, 122, 88))
    fabric(OUT / "fabric_purple.png", (112, 78, 150))
    if not (OUT / "window_view.png").exists():
        fallback_window(OUT / "window_view.png")
    print("textures ready")


if __name__ == "__main__":
    main()
