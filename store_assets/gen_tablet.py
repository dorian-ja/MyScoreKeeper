"""Compose les captures tablette marketees (paysage) pour les formats 10 pouces et 7 pouces."""
from PIL import Image, ImageDraw, ImageFont

OUT = "store_assets"
OCHRE = (200, 117, 46)
RUST = (156, 74, 30)
CREAM = (250, 243, 228)
GOLD = (232, 168, 85)

W = 2560
HEADER = 260
H = 1860


def font(name, size):
    try:
        return ImageFont.truetype(f"C:/Windows/Fonts/{name}", size)
    except OSError:
        return ImageFont.load_default()


SHOTS = [
    ("tab1_accueil.png", "Un carnet de scores pour tous vos jeux"),
    ("tab2_config.png", "Le comptage de chaque jeu, expliqué"),
    ("tab3_classement.png", "Classement et détail, calculés pour vous"),
]

f_title = font("seguibl.ttf", 72)

for i, (src, title) in enumerate(SHOTS, 1):
    canvas = Image.new("RGB", (W, H), OCHRE)
    px = canvas.load()
    for y in range(H):
        t = y / H
        row = (
            int(OCHRE[0] + (RUST[0] - OCHRE[0]) * t),
            int(OCHRE[1] + (RUST[1] - OCHRE[1]) * t),
            int(OCHRE[2] + (RUST[2] - OCHRE[2]) * t),
        )
        for x in range(W):
            px[x, y] = row
    draw = ImageDraw.Draw(canvas)

    tw = draw.textlength(title, font=f_title)
    draw.text(((W - tw) / 2, 92), title, font=f_title, fill=CREAM)
    draw.rounded_rectangle([(W - 110) / 2, 200, (W + 110) / 2, 209], radius=4, fill=GOLD)

    shot = Image.open(f"{OUT}/{src}").convert("RGB")
    target_w = 2360
    scale = target_w / shot.width
    shot = shot.resize((target_w, int(shot.height * scale)), Image.LANCZOS)
    sx = (W - target_w) // 2
    sy = HEADER + 30

    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [sx + 10, sy + 16, sx + target_w + 10, sy + shot.height + 16], radius=40, fill=(0, 0, 0, 80)
    )
    canvas.paste(Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB"), (0, 0))
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, shot.width, shot.height], radius=40, fill=255)
    canvas.paste(shot, (sx, sy), mask)

    # 10 pouces : resolution native
    canvas.save(f"{OUT}/tablet10_{i}.png")
    # 7 pouces : version redimensionnee
    w7 = 1920
    canvas.resize((w7, int(H * w7 / W)), Image.LANCZOS).save(f"{OUT}/tablet7_{i}.png")
    print(f"OK tablet10_{i}.png ({W}x{H})  +  tablet7_{i}.png ({w7}x{int(H * w7 / W)})")
