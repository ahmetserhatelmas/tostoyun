#!/usr/bin/env python3
"""Build distinct toast icons from the illustrated food art."""

from pathlib import Path

from PIL import Image, ImageDraw

SRC = Path("/tmp/orig_art")
ART = Path(__file__).resolve().parents[1] / "assets" / "art"
PREVIEW = Path("/tmp/plate_food_preview.png")


def load(name: str) -> Image.Image:
    return Image.open(SRC / f"{name}.png").convert("RGBA")


def extract(im: Image.Image, box: tuple[int, int, int, int], pred) -> Image.Image:
    crop = im.crop(box)
    px = crop.load()
    for y in range(crop.height):
        for x in range(crop.width):
            if not pred(px[x, y]):
                px[x, y] = (0, 0, 0, 0)
    bb = crop.getbbox()
    return crop.crop(bb) if bb else crop


def is_yellow(p) -> bool:
    r, g, b, a = p
    return a > 20 and r > 205 and g > 165 and b < 140 and (r - b) > 60


def is_sucuk(p) -> bool:
    r, g, b, a = p
    return a > 20 and r > 115 and r > g + 25 and r > b + 35 and g < 140


def is_ketchup(p) -> bool:
    r, g, b, a = p
    return a > 20 and r > 165 and g < 105 and b < 105 and r > g + 70


def trim_top(im: Image.Image) -> Image.Image:
    px = im.load()
    w, h = im.size
    top = 0
    for y in range(h):
        if any(not (p[3] < 12 or (p[0] > 245 and p[1] > 245 and p[2] > 245)) for p in (px[x, y] for x in range(w))):
            top = max(0, y - 6)
            break
    return im.crop((0, top, w, h))


def stamp(base: Image.Image, layer: Image.Image, cx: int, cy: int, width: int) -> None:
    h = max(1, int(layer.height * (width / layer.width)))
    layer = layer.resize((width, h), Image.Resampling.LANCZOS)
    x = int(cx - layer.width / 2)
    y = int(cy - layer.height / 2)
    base.alpha_composite(layer, (x, y))


def pieces() -> dict[str, Image.Image]:
    cheese = extract(load("cheese"), (64, 64, 210, 168), is_yellow)
    sucuk_src = load("sucuk")
    rounds = [
        extract(sucuk_src, box, is_sucuk)
        for box in ((116, 91, 180, 146), (55, 109, 117, 160), (91, 146, 159, 191), (158, 138, 206, 190))
    ]
    ketchup = extract(load("karisik"), (40, 135, 210, 250), is_ketchup)
    melt = extract(load("kasarli"), (60, 198, 178, 282), is_yellow)
    return {"cheese": cheese, "rounds": rounds, "ketchup": ketchup, "melt": melt}


def main() -> None:
    # keep ingredient art original
    for name in ("cheese", "sucuk"):
        Image.open(SRC / f"{name}.png").save(ART / f"{name}.png")

    p = pieces()
    toast = load("toast")
    sucuklu = load("sucuklu")
    kasarli = load("kasarli")

    variants: dict[str, Image.Image] = {}
    variants["toast"] = toast.copy()
    variants["sade"] = toast.copy()

    cheese_toast = toast.copy()
    stamp(cheese_toast, p["cheese"], 128, 186, 118)
    variants["toast_cheese"] = cheese_toast

    variants["toast_sucuk"] = sucuklu.copy()

    mixed = sucuklu.copy()
    stamp(mixed, p["cheese"], 128, 178, 78)
    variants["toast_mixed"] = mixed

    variants["kasarli"] = kasarli.copy()
    variants["sucuklu"] = sucuklu.copy()

    cooked = sucuklu.copy()
    stamp(cooked, p["melt"], 132, 248, 88)
    variants["toast_mixed_cooked"] = cooked

    karisik = cooked.copy()
    stamp(karisik, p["ketchup"], 128, 188, 150)
    variants["karisik"] = karisik

    ketchup_bases = {
        "toast_k": "toast",
        "toast_cheese_k": "toast_cheese",
        "toast_sucuk_k": "toast_sucuk",
        "toast_mixed_k": "toast_mixed",
        "kasarli_k": "kasarli",
        "sucuklu_k": "sucuklu",
    }
    for dest, src_name in ketchup_bases.items():
        extra = variants[src_name].copy()
        stamp(extra, p["ketchup"], 128, 188, 150)
        variants[dest] = extra

    tiles = []
    for name, img in variants.items():
        img = trim_top(img)
        img.save(ART / f"{name}.png")
        print("wrote", name, img.size)
        tile = Image.new("RGB", (240, 280), (236, 214, 176))
        preview = img.copy()
        preview.thumbnail((220, 230), Image.Resampling.LANCZOS)
        tile.paste(preview, ((240 - preview.width) // 2, 8), preview)
        ImageDraw.Draw(tile).text((8, 252), name, fill=(70, 40, 20))
        tiles.append(tile)

    sheet = Image.new("RGB", (240 * 3, 280 * 3), (236, 214, 176))
    for i, tile in enumerate(tiles):
        sheet.paste(tile, ((i % 3) * 240, (i // 3) * 280))
    sheet.save(PREVIEW)
    print("preview", PREVIEW)


if __name__ == "__main__":
    main()
