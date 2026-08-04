from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "source"
PHONE_OUT = ROOT / "en-US" / "iphone-6.9"
PAD_OUT = ROOT / "en-US" / "ipad-13"
FONT = "/System/Library/Fonts/SFNS.ttf"


def font(size: int, bold: bool = False):
    return ImageFont.truetype(FONT, size=size)


def centered(draw: ImageDraw.ImageDraw, text: str, y: int, width: int, fnt, fill, spacing=12):
    box = draw.multiline_textbbox((0, 0), text, font=fnt, align="center", spacing=spacing)
    text_width = box[2] - box[0]
    draw.multiline_text(((width - text_width) / 2, y), text, font=fnt, fill=fill, align="center", spacing=spacing)


def save_rgb(image: Image.Image, path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(path, format="PNG", optimize=True)


phone = Image.open(SOURCE / "iphone-6.3.png").convert("RGB")
pad = Image.open(SOURCE / "ipad-13.png").convert("RGB")

# 01 — Current default product screen.
save_rgb(phone.resize((1320, 2868), Image.Resampling.LANCZOS), PHONE_OUT / "01-learn-teach-connect.png")

# 02 — Learning-first action hierarchy using only the real app UI.
canvas = Image.new("RGB", (1320, 2868), "#F3F0FF")
draw = ImageDraw.Draw(canvas)
centered(draw, "Learn nearby. Teach what you know.", 135, 1320, font(68, True), "#17151F")
centered(draw, "English  •  Programming  •  Singing  •  More", 270, 1320, font(38), "#625D6C")
draw.rounded_rectangle((90, 420, 1230, 2070), radius=48, fill="white", outline="#DCD5EF", width=3)
ui = phone.crop((0, 210, 1206, 1760)).resize((1080, 1388), Image.Resampling.LANCZOS)
canvas.paste(ui, (120, 540))
centered(draw, "One place to learn, teach and connect", 2200, 1320, font(48, True), "#17151F")
centered(draw, "Built around skills and shared learning goals.", 2300, 1320, font(34), "#625D6C")
save_rgb(canvas, PHONE_OUT / "02-learning-actions.png")

# 03 — Privacy-first Nearby using the real location controls.
canvas = Image.new("RGB", (1320, 2868), "#EEF7FF")
draw = ImageDraw.Draw(canvas)
centered(draw, "Nearby, with privacy built in", 145, 1320, font(72, True), "#10243A")
centered(draw, "Share an approximate area only when you choose.", 290, 1320, font(36), "#47617B")
draw.rounded_rectangle((90, 500, 1230, 1820), radius=48, fill="white", outline="#C9DFF2", width=3)
ui = phone.crop((0, 1110, 1206, 2290)).resize((1080, 1057), Image.Resampling.LANCZOS)
canvas.paste(ui, (120, 630))
centered(draw, "You stay in control", 2050, 1320, font(52, True), "#10243A")
centered(
    draw,
    "Distance ranges instead of an exact position.\nVisibility is off until you turn it on.",
    2165,
    1320,
    font(36),
    "#47617B",
    spacing=16,
)
save_rgb(canvas, PHONE_OUT / "03-privacy-first-nearby.png")

# iPad 13-inch portrait, native Apple size.
save_rgb(pad.resize((2064, 2752), Image.Resampling.LANCZOS), PAD_OUT / "01-learning-on-ipad.png")

print(f"Generated {PHONE_OUT} and {PAD_OUT}")
