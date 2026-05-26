#!/usr/bin/env python3

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


REPO_ROOT = Path(__file__).resolve().parents[1]
BRAND_ROOT = REPO_ROOT / "Assets" / "Brand"
APP_ICONSET_DIR = BRAND_ROOT / "AppIcon.appiconset"
ICONSET_DIR = BRAND_ROOT / "OpenIsland.iconset"
INTERNAL_COLOR_DIR = BRAND_ROOT / "Internal" / "color"
INTERNAL_TEMPLATE_DIR = BRAND_ROOT / "Internal" / "template"
INTERNAL_BADGE_DIR = BRAND_ROOT / "Internal" / "badge"
ICNS_PATH = BRAND_ROOT / "OpenIsland.icns"
SVG_MASTER_PATH = BRAND_ROOT / "signal-fold-app-icon-master.svg"

SCOUT_PATTERN = [
    "..B..B..",
    "..BBBB..",
    ".BHHHHB.",
    "BBHEHEBB",
    ".BHHHHB.",
    "..BBBB..",
    ".B....B.",
    "........",
]

APP_ICON_SPECS = [
    ("icon_16x16.png", "16x16", "1x", 16),
    ("icon_16x16@2x.png", "16x16", "2x", 32),
    ("icon_32x32.png", "32x32", "1x", 32),
    ("icon_32x32@2x.png", "32x32", "2x", 64),
    ("icon_128x128.png", "128x128", "1x", 128),
    ("icon_128x128@2x.png", "128x128", "2x", 256),
    ("icon_256x256.png", "256x256", "1x", 256),
    ("icon_256x256@2x.png", "256x256", "2x", 512),
    ("icon_512x512.png", "512x512", "1x", 512),
    ("icon_512x512@2x.png", "512x512", "2x", 1024),
]

# Apple's macOS icon grid (Big Sur+): the art occupies an 824×824 region
# centered in a 1024×1024 canvas, leaving a transparent safe zone so our
# squircle visually matches stock macOS icons in Finder/Launchpad/Dock.
MACOS_ICON_CONTENT_RATIO = 824 / 1024


def main() -> None:
    ensure_clean_dir(APP_ICONSET_DIR)
    ensure_clean_dir(ICONSET_DIR)
    ensure_clean_dir(INTERNAL_COLOR_DIR)
    ensure_clean_dir(INTERNAL_TEMPLATE_DIR)
    ensure_clean_dir(INTERNAL_BADGE_DIR)
    BRAND_ROOT.mkdir(parents=True, exist_ok=True)

    write_svg_master(SVG_MASTER_PATH)
    write_app_icons()
    write_internal_assets()
    write_appiconset_contents_json(APP_ICONSET_DIR / "Contents.json")
    build_icns()


def ensure_clean_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[index : index + 2], 16) for index in range(0, 6, 2)) + (alpha,)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def solid_layer(size: tuple[int, int], color: tuple[int, int, int, int]) -> Image.Image:
    return Image.new("RGBA", size, color)


def vertical_gradient(size: tuple[int, int], top: str, bottom: str) -> Image.Image:
    top_rgba = rgba(top)
    bottom_rgba = rgba(bottom)
    image = Image.new("RGBA", size)
    pixels = image.load()
    height = max(size[1] - 1, 1)
    for y in range(size[1]):
        mix = y / height
        color = tuple(
            round(top_rgba[index] + (bottom_rgba[index] - top_rgba[index]) * mix)
            for index in range(4)
        )
        for x in range(size[0]):
            pixels[x, y] = color
    return image


def diagonal_gradient(size: tuple[int, int], top_left: str, mid: str, bottom_right: str) -> Image.Image:
    tl = rgba(top_left)
    m = rgba(mid)
    br = rgba(bottom_right)
    image = Image.new("RGBA", size)
    pixels = image.load()
    diag = max((size[0] + size[1]) - 2, 1)
    for y in range(size[1]):
        for x in range(size[0]):
            t = (x + y) / diag
            if t < 0.5:
                t2 = t * 2
                color = tuple(round(tl[i] + (m[i] - tl[i]) * t2) for i in range(4))
            else:
                t2 = (t - 0.5) * 2
                color = tuple(round(m[i] + (br[i] - m[i]) * t2) for i in range(4))
            pixels[x, y] = color
    return image


def draw_shadow(base: Image.Image, box: tuple[int, int, int, int], radius: int, color: str, blur: float) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(box, radius=radius, fill=rgba(color))
    shadow = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(shadow)


def draw_glow_ellipse(base: Image.Image, box: tuple[int, int, int, int], color: str, blur: float) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.ellipse(box, fill=rgba(color))
    glow = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(glow)


def paste_masked(base: Image.Image, overlay: Image.Image, xy: tuple[int, int], mask: Image.Image) -> None:
    base.paste(overlay, xy, mask)


def draw_app_shell(size: int) -> tuple[Image.Image, tuple[int, int, int, int]]:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    icon_size = int(size * 0.86)
    icon_x = (size - icon_size) // 2
    icon_y = (size - icon_size) // 2 - max(2, size // 64)
    outer_radius = max(12, int(icon_size * 0.24))

    face_x = icon_x
    face_y = icon_y
    face_size = icon_size
    face_radius = outer_radius

    face_gradient = diagonal_gradient((face_size, face_size), "#B8F0A8", "#88E0C0", "#78CCE8")
    face_mask = rounded_mask((face_size, face_size), face_radius)
    paste_masked(image, face_gradient, (face_x, face_y), face_mask)

    return image, (face_x, face_y, face_size, face_size)


def draw_mark_shadow(draw: ImageDraw.ImageDraw, origin: tuple[int, int], cell: int, pattern: list[str], alpha: int) -> None:
    ox, oy = origin
    offset = max(1, round(cell * 0.16))
    shadow_fill = rgba("#000000", alpha)
    for row_index, row in enumerate(pattern):
        for column_index, char in enumerate(row):
            if char == ".":
                continue
            x = ox + column_index * cell + offset
            y = oy + row_index * cell + offset
            draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=shadow_fill)


def draw_mark(
    draw: ImageDraw.ImageDraw,
    origin: tuple[int, int],
    cell: int,
    palette: dict[str, tuple[int, int, int, int]],
    include_punctuation: bool,
    silhouette_only: bool = False,
) -> None:
    ox, oy = origin

    for row_index, row in enumerate(SCOUT_PATTERN):
        for column_index, char in enumerate(row):
            if char == ".":
                continue

            fill = palette["B" if silhouette_only else char]
            x = ox + column_index * cell
            y = oy + row_index * cell
            draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=fill)

    if include_punctuation:
        x = ox + 11 * cell
        for row_index in (1, 3, 5):
            y = oy + row_index * cell
            draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=palette["P"])


def render_app_icon(size: int) -> Image.Image:
    image, face = draw_app_shell(size)
    draw = ImageDraw.Draw(image)

    face_x, face_y, face_size, face_height = face
    mark_width_units = 8
    mark_height_units = 8
    cell = max(1, min(face_size // (mark_width_units + 3), face_height // (mark_height_units + 3)))
    mark_width = mark_width_units * cell
    mark_height = mark_height_units * cell
    origin_x = face_x + (face_size - mark_width) // 2
    origin_y = face_y + (face_height - mark_height) // 2

    palette = {
        "B": rgba("#264653"),
        "H": rgba("#E9F5F2"),
        "E": rgba("#1A1C20"),
    }

    draw_mark_shadow(draw, (origin_x, origin_y), cell, SCOUT_PATTERN, 60)
    draw_mark(draw, (origin_x, origin_y), cell, palette, include_punctuation=False)
    return image


def draw_signal_fold_mark(
    draw: ImageDraw.ImageDraw,
    size: int,
    *,
    fill: tuple[int, int, int, int],
    edge: tuple[int, int, int, int],
    include_dot: bool,
) -> None:
    def point(x: float, y: float) -> tuple[int, int]:
        return (round(size * x), round(size * y))

    panes = [
        [point(0.10, 0.62), point(0.45, 0.41), point(0.54, 0.57), point(0.17, 0.81)],
        [point(0.42, 0.16), point(0.70, 0.34), point(0.70, 0.82), point(0.42, 0.64)],
        [point(0.28, 0.36), point(0.55, 0.53), point(0.48, 0.68), point(0.28, 0.55)],
        [point(0.67, 0.49), point(0.89, 0.38), point(0.89, 0.64), point(0.67, 0.80)],
    ]

    edge_width = max(1, round(size * 0.055))
    for pane in panes:
        draw.polygon(pane, fill=fill)
        draw.line(pane + [pane[0]], fill=edge, width=edge_width, joint="curve")

    if include_dot:
        radius = max(1, round(size * 0.075))
        cx, cy = point(0.50, 0.84)
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=edge)


def render_color_mark(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_signal_fold_mark(
        draw,
        size,
        fill=rgba("#182035", 220),
        edge=rgba("#6EB7FF"),
        include_dot=size >= 32,
    )
    return image


def render_template_mark(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw_signal_fold_mark(
        draw,
        size,
        fill=rgba("#000000", 150),
        edge=rgba("#000000"),
        include_dot=False,
    )
    return image


def render_badge(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bezel_size = size
    bezel_gradient = vertical_gradient((bezel_size, bezel_size), "#A7ADB4", "#575D65")
    bezel_mask = rounded_mask((bezel_size, bezel_size), max(6, int(size * 0.23)))
    paste_masked(image, bezel_gradient, (0, 0), bezel_mask)

    inset = max(2, int(size * 0.06))
    face_size = size - inset * 2
    face_gradient = vertical_gradient((face_size, face_size), "#2D3136", "#090A0D")
    face_mask = rounded_mask((face_size, face_size), max(5, int(size * 0.19)))
    paste_masked(image, face_gradient, (inset, inset), face_mask)

    mark = render_color_mark(int(face_size * 0.72)).resize((int(face_size * 0.72), int(face_size * 0.72)), Image.Resampling.LANCZOS)
    mx = inset + (face_size - mark.width) // 2
    my = inset + (face_size - mark.height) // 2
    image.alpha_composite(mark, (mx, my))
    return image


def write_app_icons() -> None:
    cat_icon_path = BRAND_ROOT / "app-icon-cat.png"
    if cat_icon_path.exists():
        src = Image.open(cat_icon_path).convert("RGBA")
        for filename, _, _, pixel_size in APP_ICON_SPECS:
            canvas = Image.new("RGBA", (pixel_size, pixel_size), (0, 0, 0, 0))
            content_size = max(1, round(pixel_size * MACOS_ICON_CONTENT_RATIO))
            offset = (pixel_size - content_size) // 2
            resized = src.resize((content_size, content_size), Image.Resampling.LANCZOS)
            canvas.alpha_composite(resized, (offset, offset))
            canvas.save(APP_ICONSET_DIR / filename)
            canvas.save(ICONSET_DIR / filename)
    else:
        for filename, _, _, pixel_size in APP_ICON_SPECS:
            icon = render_app_icon(pixel_size)
            icon.save(APP_ICONSET_DIR / filename)
            icon.save(ICONSET_DIR / filename)


def write_internal_assets() -> None:
    for size in (14, 18, 32, 64):
        render_color_mark(size).save(INTERNAL_COLOR_DIR / f"scout-mark-{size}.png")

    for size in (18, 36):
        render_template_mark(size).save(INTERNAL_TEMPLATE_DIR / f"scout-template-{size}.png")

    for size in (32, 64):
        render_badge(size).save(INTERNAL_BADGE_DIR / f"scout-badge-{size}.png")


def write_appiconset_contents_json(path: Path) -> None:
    images = [
        {
            "filename": filename,
            "idiom": "mac",
            "scale": scale,
            "size": size,
        }
        for filename, size, scale, _ in APP_ICON_SPECS
    ]
    contents = {
        "images": images,
        "info": {
            "author": "app.openisland.dev",
            "version": 1,
        },
    }
    path.write_text(json.dumps(contents, indent=2) + "\n")


def build_icns() -> None:
    if ICNS_PATH.exists():
        ICNS_PATH.unlink()

    subprocess.run(
        ["iconutil", "-c", "icns", str(ICONSET_DIR), "-o", str(ICNS_PATH)],
        check=True,
    )


def write_svg_master(path: Path) -> None:
    svg = f"""<svg width="1024" height="1024" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="face" x1="120" y1="96" x2="904" y2="928" gradientUnits="userSpaceOnUse">
      <stop stop-color="#202833"/>
      <stop offset="1" stop-color="#05070A"/>
    </linearGradient>
    <linearGradient id="pane" x1="270" y1="150" x2="760" y2="840" gradientUnits="userSpaceOnUse">
      <stop stop-color="#39404C"/>
      <stop offset="0.52" stop-color="#10182A"/>
      <stop offset="1" stop-color="#253B67"/>
    </linearGradient>
    <filter id="glow" x="120" y="90" width="790" height="850" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse">
      <feGaussianBlur stdDeviation="18"/>
    </filter>
  </defs>
  <g>
    <rect x="112" y="92" width="800" height="840" rx="196" fill="url(#face)"/>
    <rect x="112" y="92" width="800" height="840" rx="196" stroke="#79B7FF" stroke-opacity="0.64" stroke-width="12"/>
  </g>
  <g filter="url(#glow)" opacity="0.62">
    <path d="M102 635L461 420L553 584L174 830Z" stroke="#6EB7FF" stroke-width="42"/>
    <path d="M430 164L717 348V842L430 657Z" stroke="#6EB7FF" stroke-width="44"/>
    <path d="M286 369L563 543L492 698L286 563Z" stroke="#6EB7FF" stroke-width="38"/>
    <path d="M686 502L912 389V655L686 819Z" stroke="#6EB7FF" stroke-width="38"/>
  </g>
  <g>
    <path d="M102 635L461 420L553 584L174 830Z" fill="url(#pane)" stroke="#6EB7FF" stroke-width="30" stroke-linejoin="round"/>
    <path d="M430 164L717 348V842L430 657Z" fill="url(#pane)" stroke="#9ACBFF" stroke-width="34" stroke-linejoin="round"/>
    <path d="M286 369L563 543L492 698L286 563Z" fill="url(#pane)" stroke="#7E8CFF" stroke-width="28" stroke-linejoin="round"/>
    <path d="M686 502L912 389V655L686 819Z" fill="url(#pane)" stroke="#7E8CFF" stroke-width="28" stroke-linejoin="round"/>
    <circle cx="512" cy="860" r="54" fill="#76D5FF" stroke="#9ACBFF" stroke-width="18"/>
  </g>
</svg>
"""
    path.write_text(svg)


if __name__ == "__main__":
    main()
