"""Genere les visuels obligatoires du Google Play Store pour My Score Keeper."""
import os
from PIL import Image, ImageDraw, ImageFont

SRC = "assets/images"
OUT = "store_assets"
os.makedirs(OUT, exist_ok=True)

# Palette de marque
OCHRE = (200, 117, 46)      # #C8752E
RUST = (156, 74, 30)        # #9C4A1E
TEAL = (48, 88, 104)        # #305868
CREAM = (250, 243, 228)     # #FAF3E4
INK = (58, 42, 29)          # #3A2A1D
GOLD = (232, 168, 85)       # #E8A855


def font(name, size):
    for path in (f"C:/Windows/Fonts/{name}", name):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


# ---------------------------------------------------------------------------
# 1) Icone 512x512 (composite sur fond de marque, sans transparence)
# ---------------------------------------------------------------------------
icon_src = Image.open(f"{SRC}/app_icon.png").convert("RGBA")
bg = Image.new("RGBA", icon_src.size, OCHRE + (255,))
composed = Image.alpha_composite(bg, icon_src)
icon512 = composed.resize((512, 512), Image.LANCZOS).convert("RGB")
icon512.save(f"{OUT}/icon_512.png")
print("OK icon_512.png (512x512)")


# ---------------------------------------------------------------------------
# 2) Feature graphic / banniere 1024x500
# ---------------------------------------------------------------------------
W, H = 1024, 500
banner = Image.new("RGB", (W, H), OCHRE)
px = banner.load()
# Degrade diagonal ocre -> rouille
for y in range(H):
    for x in range(0, W, 2):
        t = (x / W * 0.5) + (y / H * 0.5)
        r = int(OCHRE[0] + (RUST[0] - OCHRE[0]) * t)
        g = int(OCHRE[1] + (RUST[1] - OCHRE[1]) * t)
        b = int(OCHRE[2] + (RUST[2] - OCHRE[2]) * t)
        px[x, y] = (r, g, b)
        if x + 1 < W:
            px[x + 1, y] = (r, g, b)
draw = ImageDraw.Draw(banner)

# Icone a gauche, avec ombre douce
isize = 300
icon = composed.resize((isize, isize), Image.LANCZOS)
ix, iy = 70, (H - isize) // 2
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle(
    [ix + 8, iy + 12, ix + isize + 8, iy + isize + 12], radius=60, fill=(0, 0, 0, 70)
)
banner.paste(Image.alpha_composite(banner.convert("RGBA"), shadow).convert("RGB"), (0, 0))
# masque arrondi pour l'icone
mask = Image.new("L", (isize, isize), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, isize, isize], radius=60, fill=255)
banner.paste(icon, (ix, iy), mask)

# Textes a droite
tx = ix + isize + 60
f_title = font("seguibl.ttf", 78)
f_tag = font("segoeui.ttf", 33)
f_games = font("segoeuib.ttf", 27)
draw.text((tx, 150), "My Score", font=f_title, fill=CREAM)
draw.text((tx, 232), "Keeper", font=f_title, fill=GOLD)
draw.text((tx, 330), "Comptez les points de vos", font=f_tag, fill=CREAM)
draw.text((tx, 368), "jeux de société et de cartes", font=f_tag, fill=CREAM)
banner.save(f"{OUT}/feature_graphic_1024x500.png")
print("OK feature_graphic_1024x500.png (1024x500)")
