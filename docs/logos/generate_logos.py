"""
CryptoBox — Obsidian Signal
Generate 5 logo concepts with supersampled rendering, gradient fills,
and atmospheric glow. Output: 512x512 PNG on #111417.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

# ---------- Palette ----------
BG          = (17, 20, 23)          # #111417
CYAN        = (6, 182, 212)         # #06B6D4
PRIMARY     = (0, 209, 255)         # #00D1FF
BLUE        = (59, 130, 246)        # #3B82F6
PALE        = (164, 230, 255)       # #A4E6FF
DEEP        = (10, 60, 140)         # deeper anchor

# ---------- Render config ----------
FINAL = 512
SCALE = 4                    # supersample factor
S     = FINAL * SCALE        # working canvas size
CX    = S // 2
CY    = S // 2

OUT_DIR = os.path.dirname(os.path.abspath(__file__))


# ================================================================
# Helpers
# ================================================================
def new_canvas():
    """Start with the dark Obsidian background."""
    return Image.new("RGB", (S, S), BG)


def lerp(a, b, t):
    return a + (b - a) * t


def lerp_color(c1, c2, t):
    return (
        int(lerp(c1[0], c2[0], t)),
        int(lerp(c1[1], c2[1], t)),
        int(lerp(c1[2], c2[2], t)),
    )


def multi_gradient(t, stops):
    """stops: [(pos, color), ...] sorted by pos in [0,1]."""
    if t <= stops[0][0]:
        return stops[0][1]
    if t >= stops[-1][0]:
        return stops[-1][1]
    for i in range(len(stops) - 1):
        p1, c1 = stops[i]
        p2, c2 = stops[i + 1]
        if p1 <= t <= p2:
            local = (t - p1) / (p2 - p1) if p2 > p1 else 0
            return lerp_color(c1, c2, local)
    return stops[-1][1]


# Signature gradient: pale ice → electric core → cyan → deep blue
SIGNATURE_STOPS = [
    (0.00, PALE),
    (0.25, PRIMARY),
    (0.55, CYAN),
    (1.00, BLUE),
]


def gradient_mask_image(mask, angle_deg=135, stops=SIGNATURE_STOPS):
    """Given an L mask, return an RGB image where mask=white is filled
    with a linear gradient across the image at `angle_deg`."""
    w, h = mask.size
    grad = Image.new("RGB", (w, h), BG)
    px = grad.load()
    theta = math.radians(angle_deg)
    dx, dy = math.cos(theta), math.sin(theta)
    # project corners to get min/max along direction
    projs = [0 * dx + 0 * dy, w * dx + 0 * dy, 0 * dx + h * dy, w * dx + h * dy]
    pmin, pmax = min(projs), max(projs)
    rng = pmax - pmin if pmax != pmin else 1
    for y in range(h):
        ydy = y * dy
        for x in range(w):
            t = ((x * dx + ydy) - pmin) / rng
            px[x, y] = multi_gradient(t, stops)
    out = Image.new("RGB", (w, h), BG)
    out.paste(grad, (0, 0), mask)
    return out


def radial_gradient_mask(mask, center, r_inner, r_outer, stops=SIGNATURE_STOPS):
    w, h = mask.size
    grad = Image.new("RGB", (w, h), BG)
    px = grad.load()
    cx, cy = center
    rng = max(1, r_outer - r_inner)
    for y in range(h):
        dy = y - cy
        for x in range(w):
            d = math.sqrt((x - cx) ** 2 + dy * dy)
            t = max(0.0, min(1.0, (d - r_inner) / rng))
            px[x, y] = multi_gradient(t, stops)
    out = Image.new("RGB", (w, h), BG)
    out.paste(grad, (0, 0), mask)
    return out


def add_glow(base_img, mask, blur_radius, intensity=0.85, color=None):
    """Add a soft atmospheric glow derived from `mask` onto base_img."""
    w, h = base_img.size
    if color is None:
        # use a rich cyan for the glow halo
        color = (10, 190, 235)
    glow_src = Image.new("RGB", (w, h), (0, 0, 0))
    glow_src.paste(Image.new("RGB", (w, h), color), (0, 0), mask)
    blurred = glow_src.filter(ImageFilter.GaussianBlur(blur_radius))
    # Screen blend with base
    base = base_img.convert("RGB")
    base_px = base.load()
    glow_px = blurred.load()
    inv = 1.0 - intensity
    for y in range(h):
        for x in range(w):
            br, bg, bb = base_px[x, y]
            gr, gg, gb = glow_px[x, y]
            # screen blend
            sr = 255 - int((255 - br) * (255 - gr * intensity) / 255)
            sg = 255 - int((255 - bg) * (255 - gg * intensity) / 255)
            sb = 255 - int((255 - bb) * (255 - gb * intensity) / 255)
            base_px[x, y] = (
                min(255, max(0, sr)),
                min(255, max(0, sg)),
                min(255, max(0, sb)),
            )
    return base


def finalize(img, name):
    out = img.resize((FINAL, FINAL), Image.LANCZOS)
    path = os.path.join(OUT_DIR, name)
    out.save(path, "PNG")
    print(f"  → {name}")


def stroke_w(px):
    """Convert a 'final px' stroke to supersampled px."""
    return max(1, int(round(px * SCALE)))


# ================================================================
# LOGO 1 — Hexagonal Hub
# ================================================================
def logo_1_hexagon_hub():
    print("Logo 1 — Hexagonal Hub")
    img = new_canvas()
    draw = ImageDraw.Draw(img)

    # Hexagon vertices (flat-top)
    R_hex = S * 0.18
    hex_pts = []
    for i in range(6):
        a = math.radians(60 * i - 30)  # pointy-top
        hex_pts.append((CX + R_hex * math.cos(a), CY + R_hex * math.sin(a)))

    # Outer nodes at larger radius
    R_nodes = S * 0.36
    node_pts = []
    for i in range(6):
        a = math.radians(60 * i - 30)
        node_pts.append((CX + R_nodes * math.cos(a), CY + R_nodes * math.sin(a)))

    # 1. Connector lines (behind)
    line_mask = Image.new("L", (S, S), 0)
    lm = ImageDraw.Draw(line_mask)
    lw = stroke_w(2)
    for p in node_pts:
        lm.line([(CX, CY), p], fill=255, width=lw)
    line_rgb = gradient_mask_image(line_mask, angle_deg=45)
    img.paste(line_rgb, (0, 0), line_mask)

    # 2. Hexagon outline (thicker)
    hex_mask = Image.new("L", (S, S), 0)
    hm = ImageDraw.Draw(hex_mask)
    hm.polygon(hex_pts, outline=255, fill=0)
    # thicken via line draw
    hw = stroke_w(5)
    for i in range(6):
        hm.line([hex_pts[i], hex_pts[(i + 1) % 6]], fill=255, width=hw)
    hex_rgb = gradient_mask_image(hex_mask, angle_deg=135)
    img.paste(hex_rgb, (0, 0), hex_mask)

    # 3. Inner hexagon accent (thin)
    inner_hex = [(CX + (R_hex * 0.55) * math.cos(math.radians(60 * i - 30)),
                  CY + (R_hex * 0.55) * math.sin(math.radians(60 * i - 30))) for i in range(6)]
    inner_mask = Image.new("L", (S, S), 0)
    im_draw = ImageDraw.Draw(inner_mask)
    iw = stroke_w(2)
    for i in range(6):
        im_draw.line([inner_hex[i], inner_hex[(i + 1) % 6]], fill=255, width=iw)
    inner_rgb = gradient_mask_image(inner_mask, angle_deg=135,
                                    stops=[(0, PALE), (1, PRIMARY)])
    img.paste(inner_rgb, (0, 0), inner_mask)

    # 4. Nodes (glowing dots)
    node_mask = Image.new("L", (S, S), 0)
    nm = ImageDraw.Draw(node_mask)
    node_r = stroke_w(14)
    for p in node_pts:
        nm.ellipse([p[0] - node_r, p[1] - node_r, p[0] + node_r, p[1] + node_r],
                   fill=255)
    node_rgb = gradient_mask_image(node_mask, angle_deg=90)
    img.paste(node_rgb, (0, 0), node_mask)

    # 5. Central core dot
    core_mask = Image.new("L", (S, S), 0)
    cm = ImageDraw.Draw(core_mask)
    core_r = stroke_w(10)
    cm.ellipse([CX - core_r, CY - core_r, CX + core_r, CY + core_r], fill=255)
    core_rgb = radial_gradient_mask(core_mask, (CX, CY), 0, core_r,
                                    stops=[(0, PALE), (1, PRIMARY)])
    img.paste(core_rgb, (0, 0), core_mask)

    # Glow pass — combined mask
    combined = Image.new("L", (S, S), 0)
    combined.paste(hex_mask, (0, 0), hex_mask)
    combined.paste(node_mask, (0, 0), node_mask)
    combined.paste(line_mask, (0, 0), line_mask)
    img = add_glow(img, combined, blur_radius=S * 0.02, intensity=0.55)

    finalize(img, "logo-1-hexagon-hub.png")


# ================================================================
# LOGO 2 — Stylized C
# ================================================================
def logo_2_stylized_c():
    print("Logo 2 — Stylized C")
    img = new_canvas()

    # Thick arc: open circle with a gap on the right (like a C)
    R = int(S * 0.30)
    thickness = stroke_w(46)
    box = [CX - R, CY - R, CX + R, CY + R]

    mask = Image.new("L", (S, S), 0)
    md = ImageDraw.Draw(mask)
    # Arc from 35° to 325° (gap centered right)
    md.arc(box, start=35, end=325, fill=255, width=thickness)

    # End caps — small circles for crisp rounded ends
    for ang_deg in (35, 325):
        a = math.radians(ang_deg)
        ex, ey = CX + R * math.cos(a), CY + R * math.sin(a)
        cap_r = thickness // 2
        md.ellipse([ex - cap_r, ey - cap_r, ex + cap_r, ey + cap_r], fill=255)

    rgb = gradient_mask_image(mask, angle_deg=135)
    img.paste(rgb, (0, 0), mask)

    # Inner serif notch — a small inward tick at the top-right end to suggest "C"/coin
    notch_mask = Image.new("L", (S, S), 0)
    nd = ImageDraw.Draw(notch_mask)
    # Small glowing dot just inside, near upper gap
    a = math.radians(0)
    dx, dy = CX + (R - thickness * 0.5) * math.cos(a), CY + (R - thickness * 0.5) * math.sin(a)
    dot_r = stroke_w(6)
    nd.ellipse([dx - dot_r, dy - dot_r, dx + dot_r, dy + dot_r], fill=255)
    ndot_rgb = gradient_mask_image(notch_mask, angle_deg=90,
                                   stops=[(0, PALE), (1, PRIMARY)])
    img.paste(ndot_rgb, (0, 0), notch_mask)

    # Glow
    img = add_glow(img, mask, blur_radius=S * 0.025, intensity=0.6)

    finalize(img, "logo-2-stylized-c.png")


# ================================================================
# LOGO 3 — Shield Lock
# ================================================================
def logo_3_shield_lock():
    print("Logo 3 — Shield Lock")
    img = new_canvas()

    # Shield silhouette
    w = S * 0.38
    h = S * 0.48
    top_y = CY - h * 0.55
    bot_y = CY + h * 0.55

    # Shield polygon (flat top, pointed bottom with rounded shoulders)
    shield_pts = [
        (CX - w / 2, top_y),
        (CX + w / 2, top_y),
        (CX + w / 2, CY + h * 0.05),
        (CX,         bot_y),
        (CX - w / 2, CY + h * 0.05),
    ]

    # Outline stroke
    outline_mask = Image.new("L", (S, S), 0)
    od = ImageDraw.Draw(outline_mask)
    ow = stroke_w(6)
    for i in range(len(shield_pts)):
        od.line([shield_pts[i], shield_pts[(i + 1) % len(shield_pts)]],
                fill=255, width=ow)
    # round the joints
    for p in shield_pts:
        r = ow // 2
        od.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=255)

    shield_rgb = gradient_mask_image(outline_mask, angle_deg=135)
    img.paste(shield_rgb, (0, 0), outline_mask)

    # Subtle inner fill — a faint gradient region inside the shield
    fill_mask = Image.new("L", (S, S), 0)
    fd = ImageDraw.Draw(fill_mask)
    inset = stroke_w(3)
    inner_pts = []
    for p in shield_pts:
        vx, vy = p[0] - CX, p[1] - CY
        length = math.sqrt(vx * vx + vy * vy)
        f = max(0, (length - inset)) / length if length else 1
        inner_pts.append((CX + vx * f * 0.96, CY + vy * f * 0.96))
    fd.polygon(inner_pts, fill=40)  # faint
    faint_rgb = gradient_mask_image(fill_mask, angle_deg=135,
                                    stops=[(0, (12, 40, 60)),
                                           (1, (8, 24, 48))])
    img.paste(faint_rgb, (0, 0), fill_mask)

    # Keyhole — circle + tapered slot
    kh_cx, kh_cy = CX, CY - h * 0.03
    key_r = stroke_w(18)
    kh_mask = Image.new("L", (S, S), 0)
    kd = ImageDraw.Draw(kh_mask)
    kd.ellipse([kh_cx - key_r, kh_cy - key_r, kh_cx + key_r, kh_cy + key_r], fill=255)
    # slot (trapezoid below)
    slot_top_w = stroke_w(10)
    slot_bot_w = stroke_w(18)
    slot_h = stroke_w(38)
    kd.polygon([
        (kh_cx - slot_top_w / 2, kh_cy),
        (kh_cx + slot_top_w / 2, kh_cy),
        (kh_cx + slot_bot_w / 2, kh_cy + slot_h),
        (kh_cx - slot_bot_w / 2, kh_cy + slot_h),
    ], fill=255)
    kh_rgb = radial_gradient_mask(kh_mask, (kh_cx, kh_cy - key_r * 0.5),
                                  0, key_r * 3,
                                  stops=[(0, PALE), (0.5, PRIMARY), (1, CYAN)])
    img.paste(kh_rgb, (0, 0), kh_mask)

    # Glow
    combined = Image.new("L", (S, S), 0)
    combined.paste(outline_mask, (0, 0), outline_mask)
    combined.paste(kh_mask, (0, 0), kh_mask)
    img = add_glow(img, combined, blur_radius=S * 0.022, intensity=0.55)

    finalize(img, "logo-3-shield-lock.png")


# ================================================================
# LOGO 4 — Abstract Diamond Vault
# ================================================================
def logo_4_diamond_vault():
    print("Logo 4 — Diamond Vault")
    img = new_canvas()

    # Diamond outline: top wide band, tapering to a point below
    w = S * 0.38
    top_y = CY - S * 0.18
    mid_y = CY - S * 0.05
    bot_y = CY + S * 0.30

    # 6 top vertices (hex-ish top), 1 bottom point
    top_left   = (CX - w / 2,        top_y)
    top_inl    = (CX - w / 4,        top_y - S * 0.02)
    top_inr    = (CX + w / 4,        top_y - S * 0.02)
    top_right  = (CX + w / 2,        top_y)
    mid_right  = (CX + w / 2 + S * 0.01, mid_y)
    mid_left   = (CX - w / 2 - S * 0.01, mid_y)
    bottom     = (CX, bot_y)

    outer = [top_left, top_inl, top_inr, top_right, mid_right, bottom, mid_left]

    # Outline
    out_mask = Image.new("L", (S, S), 0)
    od = ImageDraw.Draw(out_mask)
    ow = stroke_w(5)
    for i in range(len(outer)):
        od.line([outer[i], outer[(i + 1) % len(outer)]], fill=255, width=ow)
    for p in outer:
        r = ow // 2
        od.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=255)

    # Facet lines (internal)
    facet_pts = [
        (top_inl, bottom),
        (top_inr, bottom),
        (top_left, (CX, mid_y)),
        (top_right, (CX, mid_y)),
        ((CX, mid_y), bottom),
        (mid_left, (CX, mid_y)),
        (mid_right, (CX, mid_y)),
        (top_inl, (CX, mid_y)),
        (top_inr, (CX, mid_y)),
        # top band divider
        (mid_left, top_left),
        (mid_right, top_right),
        # subtle top cross
        (top_left, top_inr),
        (top_right, top_inl),
    ]
    facet_mask = Image.new("L", (S, S), 0)
    fd = ImageDraw.Draw(facet_mask)
    fw = stroke_w(2)
    for a, b in facet_pts:
        fd.line([a, b], fill=200, width=fw)

    # Faint inner fill
    fill_mask = Image.new("L", (S, S), 0)
    fdd = ImageDraw.Draw(fill_mask)
    fdd.polygon(outer, fill=55)
    fill_rgb = gradient_mask_image(fill_mask, angle_deg=110,
                                   stops=[(0, (14, 42, 66)),
                                          (1, (6, 20, 44))])
    img.paste(fill_rgb, (0, 0), fill_mask)

    facet_rgb = gradient_mask_image(facet_mask, angle_deg=135,
                                    stops=[(0, PALE), (1, BLUE)])
    img.paste(facet_rgb, (0, 0), facet_mask)

    out_rgb = gradient_mask_image(out_mask, angle_deg=135)
    img.paste(out_rgb, (0, 0), out_mask)

    combined = Image.new("L", (S, S), 0)
    combined.paste(out_mask, (0, 0), out_mask)
    img = add_glow(img, combined, blur_radius=S * 0.022, intensity=0.55)

    finalize(img, "logo-4-diamond-vault.png")


# ================================================================
# LOGO 5 — Minimalist Orbit
# ================================================================
def logo_5_orbit():
    print("Logo 5 — Minimalist Orbit")
    img = new_canvas()

    # 3 concentric circles
    radii = [int(S * 0.14), int(S * 0.23), int(S * 0.33)]
    widths = [stroke_w(3), stroke_w(2), stroke_w(2)]

    ring_mask = Image.new("L", (S, S), 0)
    rd = ImageDraw.Draw(ring_mask)
    for r, w in zip(radii, widths):
        rd.ellipse([CX - r, CY - r, CX + r, CY + r], outline=255, width=w)

    ring_rgb = gradient_mask_image(ring_mask, angle_deg=135)
    img.paste(ring_rgb, (0, 0), ring_mask)

    # Orbiting dots — 2 on middle ring, 4 on outer ring, offset by phase
    dots_mask = Image.new("L", (S, S), 0)
    dd = ImageDraw.Draw(dots_mask)

    dot_specs = [
        (radii[1], 30,  stroke_w(9)),
        (radii[1], 210, stroke_w(9)),
        (radii[2], 0,   stroke_w(11)),
        (radii[2], 90,  stroke_w(7)),
        (radii[2], 180, stroke_w(9)),
        (radii[2], 270, stroke_w(7)),
    ]
    for r, ang, size in dot_specs:
        a = math.radians(ang)
        x = CX + r * math.cos(a)
        y = CY + r * math.sin(a)
        dd.ellipse([x - size, y - size, x + size, y + size], fill=255)

    dots_rgb = gradient_mask_image(dots_mask, angle_deg=90,
                                   stops=[(0, PALE), (1, PRIMARY)])
    img.paste(dots_rgb, (0, 0), dots_mask)

    # Central core
    core_mask = Image.new("L", (S, S), 0)
    cd = ImageDraw.Draw(core_mask)
    cr = stroke_w(14)
    cd.ellipse([CX - cr, CY - cr, CX + cr, CY + cr], fill=255)
    core_rgb = radial_gradient_mask(core_mask, (CX, CY), 0, cr,
                                    stops=[(0, PALE), (1, PRIMARY)])
    img.paste(core_rgb, (0, 0), core_mask)

    # Glow
    combined = Image.new("L", (S, S), 0)
    combined.paste(ring_mask, (0, 0), ring_mask)
    combined.paste(dots_mask, (0, 0), dots_mask)
    combined.paste(core_mask, (0, 0), core_mask)
    img = add_glow(img, combined, blur_radius=S * 0.025, intensity=0.6)

    finalize(img, "logo-5-orbit.png")


# ================================================================
if __name__ == "__main__":
    print(f"Rendering at {S}x{S}, downscaling to {FINAL}x{FINAL}")
    logo_1_hexagon_hub()
    logo_2_stylized_c()
    logo_3_shield_lock()
    logo_4_diamond_vault()
    logo_5_orbit()
    print("Done.")
