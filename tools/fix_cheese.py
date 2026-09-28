#!/usr/bin/env python3
"""Rebuild toast_cheese variants by stamping a real cheese slice from cheese.png."""
from PIL import Image, ImageFilter, ImageEnhance
import os

ART = os.path.join(os.path.dirname(__file__), "..", "assets", "art")


def load(name):
    return Image.open(os.path.join(ART, name)).convert("RGBA")


def cheese_slice():
    """Extract the top cheese slice from cheese.png (stack on plate)."""
    im = load("cheese.png")
    w, h = im.size
    # Top slice face is roughly the upper diamond of the stack.
    crop = im.crop((int(w * 0.22), int(h * 0.16), int(w * 0.99), int(h * 0.52)))
    # Keep only yellow pixels (drop plate / background).
    px = crop.load()
    cw, ch = crop.size
    for y in range(ch):
        for x in range(cw):
            r, g, b, a = px[x, y]
            yellowness = min(r, g) - b
            if a < 30 or yellowness < 25:
                px[x, y] = (r, g, b, 0)
    # Trim to content.
    bbox = crop.getbbox()
    if bbox:
        crop = crop.crop(bbox)
    return crop


def stamp(base_name, out_name, slice_img, cx, cy, width_ratio, rot, squash=1.0):
    base = load(base_name)
    bw, bh = base.size
    target_w = int(bw * width_ratio)
    ratio = target_w / slice_img.width
    target_h = max(1, int(slice_img.height * ratio * squash))
    piece = slice_img.resize((target_w, target_h), Image.LANCZOS)
    piece = piece.rotate(rot, expand=True, resample=Image.BICUBIC)
    # Soft drop shadow
    shadow = Image.new("RGBA", piece.size, (0, 0, 0, 0))
    alpha = piece.split()[3].point(lambda a: int(a * 0.35))
    shadow.paste((60, 30, 10, 255), (0, 0), alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(3))
    px_ = int(bw * cx - piece.width / 2)
    py_ = int(bh * cy - piece.height / 2)
    out = base.copy()
    out.alpha_composite(shadow, (px_ + 2, py_ + 5))
    out.alpha_composite(piece, (px_, py_))
    out.save(os.path.join(ART, out_name))
    print("wrote", out_name, out.size)


def main():
    sl = cheese_slice()
    # Slightly deepen color so it pops on the toasted bread.
    sl = ImageEnhance.Color(sl).enhance(1.08)
    # toast.png / toast_k.png: bread face center ~ (0.47, 0.40)
    stamp("toast.png", "toast_cheese.png", sl, 0.47, 0.38, 0.58, -8)
    stamp("toast_k.png", "toast_cheese_k.png", sl, 0.47, 0.38, 0.58, -8)
    # toast_sucuk variants are wider (275x181), sucuk sits on top; cheese under/beside
    stamp("toast_sucuk.png", "toast_mixed.png", sl, 0.42, 0.36, 0.46, -6)
    stamp("toast_sucuk_k.png", "toast_mixed_k.png", sl, 0.42, 0.36, 0.46, -6)


if __name__ == "__main__":
    main()
