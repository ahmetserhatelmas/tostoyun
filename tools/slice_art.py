#!/usr/bin/env python3
from pathlib import Path
from PIL import Image

SRC = Path("/Users/serhatelmas/.cursor/projects/Users-serhatelmas-Desktop-tostoyun/assets")
OUT = Path("/Users/serhatelmas/Desktop/tostoyun/assets/art")
OUT.mkdir(parents=True, exist_ok=True)


def key_bg(im, thresh=22):
    px = im.load()
    bg = px[4, 4]
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if abs(r - bg[0]) <= thresh and abs(g - bg[1]) <= thresh and abs(b - bg[2]) <= thresh:
                px[x, y] = (0, 0, 0, 0)
    return im


def split_row(im: Image.Image, count: int, top: float, bottom: float, names: list[str], pad: float = 0.01):
    w, h = im.size
    y0, y1 = int(h * top), int(h * bottom)
    cell = w / count
    for i, name in enumerate(names):
        x0 = int(cell * i + w * pad)
        x1 = int(cell * (i + 1) - w * pad)
        crop = key_bg(im.crop((x0, y0, x1, y1)).copy())
        crop.save(OUT / f"{name}.png")
        print("wrote", name, crop.size)


def main():
    bg = Image.open(SRC / "bg_restaurant.png").convert("RGB")
    bg.save(OUT / "bg_restaurant.png")
    menu = Image.open(SRC / "menu_hero.png").convert("RGB")
    menu.save(OUT / "menu_hero.png")

    food = Image.open(SRC / "food_sheet.png").convert("RGBA")
    split_row(food, 5, 0.02, 0.50, ["toast", "kasarli", "sucuklu", "karisik", "ayran"])
    split_row(food, 5, 0.50, 0.98, ["bread", "cheese", "sucuk", "ketchup", "toaster"])

    people = Image.open(SRC / "customers_sheet.png").convert("RGBA")
    split_row(people, 4, 0.05, 0.98, ["customer_a", "customer_b", "customer_c", "customer_d"], pad=0.012)

    # extras used by item logic
    for src, dst in [
        ("toast", "sade"),
        ("toast", "toast_cheese"),
        ("toast", "toast_sucuk"),
        ("toast", "toast_mixed"),
        ("karisik", "toast_mixed_cooked"),
        ("toast", "burnt"),
    ]:
        Image.open(OUT / f"{src}.png").save(OUT / f"{dst}.png")

    burnt = Image.open(OUT / "toast.png").convert("RGBA")
    dark = Image.new("RGBA", burnt.size, (30, 20, 16, 110))
    Image.alpha_composite(burnt, dark).save(OUT / "burnt.png")
    print("art ready")


if __name__ == "__main__":
    main()
