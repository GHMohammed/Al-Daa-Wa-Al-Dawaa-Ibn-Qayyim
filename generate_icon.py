#!/usr/bin/env python3
"""
generate_icon.py
رسم أيقونة التطبيق: كتاب مفتوح أبيض على خلفية #0a3d2e
المخرجات:
  assets/images/app_icon.png — 1024×1024 (تُستخدم للأيقونة العادية والـ adaptive)
"""

import os
import sys

# ── تحقق من Pillow وثبّتها إن لم تكن موجودة ──────────────────────────────────
try:
    from PIL import Image, ImageDraw, __version__ as PIL_VERSION
    print(f'[OK] Pillow {PIL_VERSION} found')
except ImportError:
    print('[..] Pillow not found, installing...')
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'Pillow'])
    from PIL import Image, ImageDraw, __version__ as PIL_VERSION
    print(f'[OK] Pillow {PIL_VERSION} installed')

# ── الثوابت ───────────────────────────────────────────────────────────────────
SIZE   = 1024
BG     = (10,  61,  46, 255)   # #0a3d2e  — خلفية داكنة
BOOK   = (255, 255, 255, 255)  # أبيض — لون الكتاب
SHADE  = (200, 230, 220, 255)  # أبيض مائل للرمادي الفاتح للأجزاء الداخلية
TRANSP = (0,   0,   0,  0)     # شفاف


# ── أداة رسم مستطيل بزوايا دائرية (تعمل مع جميع إصدارات Pillow) ─────────────
def rounded_rect(draw, box, radius, fill):
    """ارسم مستطيلاً بزوايا دائرية — يدعم Pillow قديم وجديد"""
    x1, y1, x2, y2 = box
    try:
        draw.rounded_rectangle([x1, y1, x2, y2], radius=radius, fill=fill)
    except AttributeError:
        # Pillow < 8.2 — نرسمه يدوياً
        r = radius
        draw.rectangle([x1 + r, y1, x2 - r, y2], fill=fill)
        draw.rectangle([x1, y1 + r, x2, y2 - r], fill=fill)
        draw.ellipse([x1, y1, x1 + 2*r, y1 + 2*r], fill=fill)
        draw.ellipse([x2 - 2*r, y1, x2, y1 + 2*r], fill=fill)
        draw.ellipse([x1, y2 - 2*r, x1 + 2*r, y2], fill=fill)
        draw.ellipse([x2 - 2*r, y2 - 2*r, x2, y2], fill=fill)


# ── دالة رسم الكتاب المفتوح ───────────────────────────────────────────────────
def draw_open_book(draw, cx, cy, book_w=600, book_h=440):
    """
    يرسم كتاباً مفتوحاً مشابهاً لـ Icons.menu_book_rounded
    cx, cy  — مركز الرسم
    book_w  — العرض الكلي للكتاب
    book_h  — الارتفاع
    """
    hw     = book_w // 2   # نصف العرض
    hh     = book_h // 2   # نصف الارتفاع
    spine  = 20            # عرض العمود الفقري
    radius = 28            # انحناء الزوايا

    # ── الصفحة اليسرى ───────────────────────────────────────────────────────
    rounded_rect(draw,
                 [cx - hw, cy - hh, cx - spine // 2, cy + hh],
                 radius=radius, fill=BOOK)

    # ── الصفحة اليمنى ───────────────────────────────────────────────────────
    rounded_rect(draw,
                 [cx + spine // 2, cy - hh, cx + hw, cy + hh],
                 radius=radius, fill=BOOK)

    # ── العمود الفقري (أغمق) ────────────────────────────────────────────────
    draw.rectangle([cx - spine // 2, cy - hh, cx + spine // 2, cy + hh],
                   fill=SHADE)

    # ── شريط الغلاف العلوي (يُعطي إحساساً بسُمك الكتاب) ────────────────────
    cover_h = 36
    rounded_rect(draw,
                 [cx - hw, cy - hh, cx - spine // 2, cy - hh + cover_h],
                 radius=radius, fill=SHADE)
    rounded_rect(draw,
                 [cx + spine // 2, cy - hh, cx + hw, cy - hh + cover_h],
                 radius=radius, fill=SHADE)

    # ── أسطر النص على الصفحة اليسرى ─────────────────────────────────────────
    line_h    = 22     # ارتفاع كل سطر
    line_gap  = 50     # مسافة بين الأسطر
    margin_x  = 50     # هامش أفقي
    first_y   = cy - hh + 100  # بداية أول سطر (بعد شريط الغلاف)

    left_x1 = cx - hw + margin_x
    left_x2 = cx - spine // 2 - margin_x

    for i in range(5):
        y = first_y + i * line_gap
        # السطر الثالث أقصر قليلاً لإضفاء طابع طبيعي
        x2 = left_x2 - (80 if i == 2 else 0)
        rounded_rect(draw, [left_x1, y, x2, y + line_h], radius=11, fill=SHADE)

    # ── أسطر النص على الصفحة اليمنى ─────────────────────────────────────────
    right_x1 = cx + spine // 2 + margin_x
    right_x2 = cx + hw - margin_x

    for i in range(5):
        y = first_y + i * line_gap
        x2 = right_x2 - (80 if i == 1 else 0)
        rounded_rect(draw, [right_x1, y, x2, y + line_h], radius=11, fill=SHADE)


# ── توليد الصورتين ────────────────────────────────────────────────────────────
def main():
    script_dir  = os.path.dirname(os.path.abspath(__file__))
    assets_dir  = os.path.join(script_dir, 'assets', 'images')
    os.makedirs(assets_dir, exist_ok=True)

    # app_icon.png — أيقونة كاملة مع خلفية (تُستخدم للعادية والـ adaptive)
    img_full = Image.new('RGBA', (SIZE, SIZE), BG)
    draw_open_book(ImageDraw.Draw(img_full),
                   cx=SIZE // 2, cy=SIZE // 2,
                   book_w=580, book_h=440)
    path_full = os.path.join(assets_dir, 'app_icon.png')
    img_full.convert('RGB').save(path_full, 'PNG', optimize=True)
    print('[OK] ' + path_full + '  (' + str(os.path.getsize(path_full)) + ' bytes)')

    print('')
    print('Done! app_icon.png created successfully')
    print('Next steps:')
    print('  flutter pub get')
    print('  dart run flutter_launcher_icons')
    print('  flutter clean')
    print('  flutter run')


if __name__ == '__main__':
    main()
