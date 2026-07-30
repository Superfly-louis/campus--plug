from PIL import Image, ImageDraw
from pathlib import Path

src = Path(
    r"C:\Users\DATABYTES\.cursor\projects\c-Users-DATABYTES-Louis-campus-plug\assets"
    r"\c__Users_DATABYTES_AppData_Roaming_Cursor_User_workspaceStorage_"
    r"1ce6ff8202fe1bac997707fd28f6229d_images_image-84a23123-76e4-4da7-a341-7bd6fb7209e7.png"
)
out_dir = Path(r"c:\Users\DATABYTES\Louis\campus--plug\mobile_app\assets\images")
out_dir.mkdir(parents=True, exist_ok=True)

img = Image.open(src).convert("RGBA")
print("source", img.size)

pixels = img.load()
w, h = img.size
for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        if a > 0 and r < 40 and g < 40 and b < 40:
            pixels[x, y] = (255, 255, 255, 255)


def content_bbox(im, threshold=245):
    px = im.load()
    ww, hh = im.size
    minx, miny, maxx, maxy = ww, hh, 0, 0
    found = False
    for yy in range(hh):
        for xx in range(ww):
            r, g, b, a = px[xx, yy]
            if a < 10:
                continue
            if r < threshold or g < threshold or b < threshold:
                found = True
                minx = min(minx, xx)
                miny = min(miny, yy)
                maxx = max(maxx, xx)
                maxy = max(maxy, yy)
    if not found:
        return (0, 0, ww, hh)
    pad = 8
    return (
        max(0, minx - pad),
        max(0, miny - pad),
        min(ww, maxx + 1 + pad),
        min(hh, maxy + 1 + pad),
    )


bbox = content_bbox(img)
cropped = img.crop(bbox)
print("cropped", cropped.size, bbox)

size = 1024
canvas = Image.new("RGBA", (size, size), (255, 255, 255, 255))

pad = 90
max_side = size - pad * 2
cw, ch = cropped.size
scale = min(max_side / cw, max_side / ch)
nw, nh = int(cw * scale), int(ch * scale)
logo = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
ox = (size - nw) // 2
oy = (size - nh) // 2
canvas.paste(logo, (ox, oy), logo)

# Soft rounded square (>= 20px; ~180 looks like a real app icon)
radius = 180
mask = Image.new("L", (size, size), 0)
draw = ImageDraw.Draw(mask)
draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)

rounded = Image.new("RGBA", (size, size), (0, 0, 0, 0))
rounded.paste(canvas, (0, 0))
rounded.putalpha(mask)

icon_path = out_dir / "app_icon.png"
rounded.save(icon_path, "PNG")
print("wrote", icon_path, rounded.size)

fg = Image.new("RGBA", (size, size), (255, 255, 255, 255))
fg.paste(logo, (ox, oy), logo)
fg_path = out_dir / "app_icon_foreground.png"
fg.save(fg_path, "PNG")
print("wrote", fg_path)
