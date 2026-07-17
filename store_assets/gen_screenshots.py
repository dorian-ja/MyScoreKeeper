"""Compose des captures 'marketees' Play Store : fond de marque + titre + screenshot encadre."""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = "store_assets"
OCHRE = (200, 117, 46)
RUST = (156, 74, 30)
CREAM = (250, 243, 228)
GOLD = (232, 168, 85)

W, H = 1080, 2400
HEADER = 430  # hauteur bandeau titre


def font(name, size):
    try:
        return ImageFont.truetype(f"C:/Windows/Fonts/{name}", size)
    except OSError:
        return ImageFont.load_default()


def wrap(draw, text, fnt, max_w):
    words, lines, cur = text.split(), [], ""
    for w in words:
        test = (cur + " " + w).strip()
        if draw.textlength(test, font=fnt) <= max_w:
            cur = test
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


SHOTS = [
    ("sc1_accueil.png", "Tous vos jeux de société réunis"),
    ("sc2_config.png", "Un comptage clair, expliqué"),
    ("sc3_calcul.png", "Les points calculés en direct"),
    ("sc4_classement.png", "Le classement, automatique"),
]

f_title = font("seguibl.ttf", 60)

for i, (src, title) in enumerate(SHOTS, 1):
    canvas = Image.new("RGB", (W, H), OCHRE)
    px = canvas.load()
    for y in range(H):
        t = y / H
        px_row = (
            int(OCHRE[0] + (RUST[0] - OCHRE[0]) * t),
            int(OCHRE[1] + (RUST[1] - OCHRE[1]) * t),
            int(OCHRE[2] + (RUST[2] - OCHRE[2]) * t),
        )
        for x in range(W):
            px[x, y] = px_row
    draw = ImageDraw.Draw(canvas)

    # Titre centre, wrap sur 2 lignes max
    lines = wrap(draw, title, f_title, W - 140)
    ty = 130 if len(lines) > 1 else 175
    for ln in lines:
        tw = draw.textlength(ln, font=f_title)
        draw.text(((W - tw) / 2, ty), ln, font=f_title, fill=CREAM)
        ty += 78
    # petit trait accent dore
    draw.rounded_rectangle([(W - 90) / 2, ty + 18, (W + 90) / 2, ty + 26], radius=4, fill=GOLD)

    # Screenshot encadre
    shot = Image.open(f"{OUT}/{src}").convert("RGB")
    target_w = 858
    scale = target_w / shot.width
    shot = shot.resize((target_w, int(shot.height * scale)), Image.LANCZOS)
    sx = (W - target_w) // 2
    sy = HEADER + 40
    # ombre
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [sx + 10, sy + 16, sx + target_w + 10, sy + shot.height + 16], radius=44, fill=(0, 0, 0, 80)
    )
    canvas.paste(Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB"), (0, 0))
    # coins arrondis
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, shot.width, shot.height], radius=44, fill=255)
    canvas.paste(shot, (sx, sy), mask)

    out = f"{OUT}/store_screenshot_{i}.png"
    canvas.save(out)
    print("OK", out)
