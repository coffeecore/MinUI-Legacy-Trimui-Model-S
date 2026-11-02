#!/usr/bin/env python3
"""Generate MinUI Legacy previews and source-resource annotations.

Uses *local* MinUI res/ PNGs and BPreplayBold.otf. Based on the SDL placement
in coffeecore/MinUI-Legacy-Trimui-Model-S, branch picoarch, src/MinUI/main.c.

    python3 minui-ui-preview-annotated.py ./res --out ./ui-preview

Output: normal 320x240 samples, annotated larger images, and a res/ image atlas.
These are design previews, not pixel-perfect captures from SDL/Trimui hardware.
"""
import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

W, H = 320, 240
WHITE = (255, 255, 255)
GOLD = (210, 180, 108)
BUTTON_GOLD = (159, 137, 82)
SHADOW = (104, 90, 53)


def info_font(size, bold=False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    try:
        return ImageFont.truetype(name, size)
    except OSError:
        return ImageFont.load_default()


class Preview:
    def __init__(self, resources):
        self.res = Path(resources)
        required = (
            "BPreplayBold.otf", "title-bg.png", "tips-bar-bg.png",
            "logo.png", "list-selected-bg.png", "nav-bar-item-bg.png",
            "stat-menu-icon.png", "power-80%-icon.png",
            "settings-bar-empty.png", "settings-bar-full.png",
            "settings-icon-brightness.png", "settings-icon-volume.png",
            "roms.png", "wake.png",
        )
        missing = [name for name in required if not (self.res / name).is_file()]
        if missing:
            raise FileNotFoundError("Missing MinUI res/ files: " + ", ".join(missing))
        self.font = ImageFont.truetype(self.res / "BPreplayBold.otf", 16)
        self.tiny = ImageFont.truetype(self.res / "BPreplayBold.otf", 14)
        self.cache = {}
        self.regions = []

    def asset(self, name):
        if name not in self.cache:
            self.cache[name] = Image.open(self.res / name).convert("RGBA")
        return self.cache[name]

    def mark(self, name, x, y, note=""):
        self.regions.append((name, (x, y), note))

    def paste(self, screen, name, x, y, *, marker=None, note=""):
        sprite = self.asset(name)
        screen.alpha_composite(sprite, (x, y))
        if marker is None:
            marker = (min(W - 1, x + min(sprite.width // 2, 100)),
                      min(H - 1, y + sprite.height // 2))
        self.mark("res/" + name, *marker, note)

    def write(self, screen, text, x, y, *, font=None, fill=WHITE, crop=None):
        # This is a close preview of SDL_ttf, not exact SDL glyph rasterization.
        font = font or self.font
        layer = Image.new("RGBA", (max(W, int(font.getlength(text)) + 4), 28))
        ImageDraw.Draw(layer).text((0, 0), text, font=font, fill=(*fill, 255), anchor="lt")
        if crop is not None:
            layer = layer.crop((0, 0, crop, layer.height))
        screen.alpha_composite(layer, (x, y))

    def render(self, entries, selected=0, *, back=False, resume=False,
               prefer_picoarch=True, setting=None):
        if not entries or not 0 <= selected < len(entries):
            raise ValueError("Need entries and a valid selection")
        self.regions = []
        screen = Image.new("RGBA", (W, H), (0, 0, 0, 255))
        self.paste(screen, "title-bg.png", 0, 0, marker=(132, 2), note="bandeau haut")
        self.paste(screen, "tips-bar-bg.png", 0, 202, marker=(130, 203), note="bandeau bas")
        self.paste(screen, "logo.png", 10, 10, note="logo MinUI")

        if setting:
            kind, value, maximum = setting
            icon = ("settings-icon-brightness.png" if kind == "brightness"
                    else "settings-icon-volume.png")
            self.paste(screen, icon, 178, 9, note="icone de reglage")
            self.paste(screen, "settings-bar-empty.png", 202, 16,
                       marker=(225, 18), note="jauge vide")
            width = max(0, min(108, int(108 * value / maximum)))
            bar = self.asset("settings-bar-full.png").crop((0, 0, width, 4))
            screen.alpha_composite(bar, (202, 16))
            self.mark("res/settings-bar-full.png", 202 + max(1, width // 2), 18,
                      "portion remplie")
        else:
            self.write(screen, f"/{len(entries)}", 184, 9, font=self.tiny, fill=GOLD)
            position = str(selected + 1)
            self.write(screen, position, 184 - round(self.tiny.getlength(position)),
                       9, font=self.tiny, fill=GOLD)
            if not prefer_picoarch:
                self.write(screen, "M", 278, 7, font=self.tiny, fill=GOLD)
            self.paste(screen, "power-80%-icon.png", 294, 6,
                       note="exemple de batterie a 80 %")

        if resume:
            self.paste(screen, "nav-bar-item-bg.png", 10, 210,
                       note="bouton X / RESUME")
            self.write(screen, "X", 16, 211, fill=BUTTON_GOLD)
            self.write(screen, "RESUME", 35, 212, font=self.tiny)
        else:
            self.paste(screen, "stat-menu-icon.png", 10, 210,
                       note="MENU / SLEEP")
            self.write(screen, "SLEEP", 56, 212, font=self.tiny)

        self.paste(screen, "nav-bar-item-bg.png", 251, 210,
                   note="bouton A / OPEN")
        self.write(screen, "A", 257, 211, fill=BUTTON_GOLD)
        self.write(screen, "OPEN", 276, 212, font=self.tiny)
        if back:
            self.paste(screen, "nav-bar-item-bg.png", 183, 210,
                       note="bouton B / BACK")
            self.write(screen, "B", 190, 211, fill=BUTTON_GOLD)
            self.write(screen, "BACK", 208, 212, font=self.tiny)

        start = min(max(0, selected - 4), max(0, len(entries) - 5))
        for row, i in enumerate(range(start, min(len(entries), start + 5))):
            y = 38 + row * 32
            if i == selected:
                self.paste(screen, "list-selected-bg.png", 0, y,
                           marker=(140, y + 15), note="ligne selectionnee")
                self.write(screen, entries[i], 17, y + 8,
                           fill=SHADOW, crop=288)
            self.write(screen, entries[i], 16, y + 6, crop=288)

        self.mark("res/BPreplayBold.otf", 80, 38 + 6 + 16,
                  "texte des listes et boutons (16 / 14 px)")
        if not setting:
            self.mark("res/BPreplayBold.otf", 173, 14,
                      "compteur et etiquette M : textes dessines par C")
        return screen.convert("RGB"), list(self.regions)


def annotate(image, regions, title, subtitle=""):
    """Add labels to the right of, not on top of, the original 320x240 image."""
    factor = 3
    sw, sh = W * factor, H * factor
    margin, sidebar = 24, 580
    width, height = margin + sw + margin + sidebar, sh + 2 * margin
    canvas = Image.new("RGB", (width, height), "#131313")
    draw = ImageDraw.Draw(canvas)
    canvas.paste(image.resize((sw, sh), Image.Resampling.NEAREST), (margin, margin))
    draw.rectangle((margin-1, margin-1, margin+sw, margin+sh),
                   outline="#d2b46c", width=2)

    right_x = margin * 2 + sw
    draw.text((right_x, 21), title, font=info_font(25, True), fill="#f4e9c4")
    draw.text((right_x, 56), subtitle, font=info_font(14), fill="#c3c3c3")
    draw.line((right_x, 84, width - 24, 84), fill="#75653c", width=2)

    # Preserve every asset used, including repeated backgrounds for A and B.
    # Sort to make the legend more readable; labels are linked to their true 320x240 coordinates.
    regions = sorted(regions, key=lambda r: (r[1][1], r[1][0]))
    top, bottom = 100, height - 22
    step = min(46, (bottom - top) / max(len(regions), 1))
    for i, (asset, (x, y), note) in enumerate(regions, start=1):
        legend_y = int(top + (i - 1) * step)
        marker_x, marker_y = margin + int(x) * factor, margin + int(y) * factor
        # Connector lines avoid cluttering the screenshot: from the actual
        # resource anchor to the right-side legend only.
        color = "#efc667" if i % 2 else "#9cd5c0"
        draw.line((marker_x, marker_y, right_x-12, legend_y+10), fill=color, width=2)
        draw.ellipse((marker_x-13, marker_y-13, marker_x+13, marker_y+13),
                     fill="#202020", outline=color, width=3)
        nfont = info_font(13, True)
        nb = draw.textbbox((0, 0), str(i), font=nfont)
        draw.text((marker_x-(nb[2]-nb[0])/2, marker_y-(nb[3]-nb[1])/2-2),
                  str(i), font=nfont, fill="#ffffff")

        draw.text((right_x, legend_y), f"{i:02d}  {asset}",
                  font=info_font(17, True), fill=color)
        if note:
            draw.text((right_x+35, legend_y + 20), note,
                      font=info_font(12), fill="#d0d0d0")
    return canvas


def asset_atlas(resources):
    """One reference image showing actual PNG contents (not replacement art)."""
    assets = sorted(Path(resources).glob("*.png"))
    cell_w, cell_h, columns = 292, 160, 4
    rows = math.ceil(len(assets) / columns)
    out = Image.new("RGB", (columns * cell_w, rows * cell_h + 58), "#171717")
    d = ImageDraw.Draw(out)
    d.text((18, 12), "MinUI Legacy — ressources reelles de res/",
           font=info_font(26, True), fill="#edcf7d")
    for i, path in enumerate(assets):
        x, y = (i % columns) * cell_w, (i // columns) * cell_h + 58
        d.rectangle((x+7, y+5, x+cell_w-7, y+cell_h-5),
                    fill="#282828", outline="#796a42", width=1)
        sprite = Image.open(path).convert("RGBA")
        # checkerboard-like backdrop for transparent areas
        box = Image.new("RGB", (268, 105), "#101010")
        preview = ImageOps.contain(sprite, (264, 101), Image.Resampling.NEAREST)
        box.paste(preview, ((268-preview.width)//2, (105-preview.height)//2), preview)
        out.paste(box, (x+12, y+10))
        d.text((x+12, y+119), "res/" + path.name,
               font=info_font(13), fill="#f8f1dd")
        d.text((x+12, y+139), f"{sprite.width} × {sprite.height}",
               font=info_font(11), fill="#bababa")
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("res", help="Real local MinUI res/ directory")
    ap.add_argument("--out", type=Path, default=Path("minui-previews"))
    args = ap.parse_args()
    p = Preview(args.res)
    args.out.mkdir(parents=True, exist_ok=True)
    annotated_dir = args.out / "annotated"
    annotated_dir.mkdir(exist_ok=True)

    # Text labels here are EXAMPLES, not copied from the user's SD card.
    samples = (
        ("01-root.png", "Menu principal", dict(
            entries=["Recently Played", "Game Boy", "PlayStation",
                     "Pokemon Mini", "Super Nintendo", "Games", "Tools"])),
        ("02-games.png", "Dossier Games", dict(
            entries=["Doom", "Cave Story", "Quake", "OpenTyrian"], back=True)),
        ("03-game-boy.png", "Liste des ROMs", dict(
            entries=["Tetris", "Pokemon Red", "Kirby's Dream Land",
                     "Metroid II", "Super Mario Land", "Wario Land"],
            selected=1, back=True)),
        ("04-brightness.png", "Reglage luminosite", dict(
            entries=["Recently Played", "Game Boy", "PlayStation",
                     "Pokemon Mini", "Super Nintendo"], selected=1,
            setting=("brightness", 7, 10))),
        ("05-volume.png", "Reglage volume", dict(
            entries=["Recently Played", "Game Boy", "PlayStation",
                     "Pokemon Mini", "Super Nintendo"], selected=1,
            setting=("volume", 15, 20))),
    )
    for name, title, options in samples:
        image, regions = p.render(**options)
        image.save(args.out / name)
        annotate(image, regions, title, "Nom reel des fichiers utilises, a droite").save(
            annotated_dir / name)
        print(name, "->", annotated_dir / name)

    for name, title, resource in (
        ("06-no-roms.png", "Aucune ROM", "roms.png"),
        ("07-wake.png", "Sortie de veille", "wake.png"),
    ):
        image = p.asset(resource).convert("RGB")
        image.save(args.out / name)
        regions = [("res/" + resource, (160, 120), "PNG affiche en plein ecran")]
        annotate(image, regions, title, "Ecran fixe provenant du PNG original").save(
            annotated_dir / name)
        print(name, "->", annotated_dir / name)

    atlas = args.out / "00-res-assets-atlas.png"
    asset_atlas(p.res).save(atlas)
    print("Planche des ressources :", atlas)
    print("Termine : 7 captures, 7 versions annotees, 1 planche res/.")


if __name__ == "__main__":
    main()
