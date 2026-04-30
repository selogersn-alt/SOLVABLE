"""
Script de migration rétroactif — Filigrane Loger Sénégal
=========================================================
Ce script applique le filigrane sur TOUTES les images existantes
déjà enregistrées en base de données, y compris les annonces publiées avant
l'activation du système de filigrane automatique.

Utilisation (sur le serveur O2switch) :
    python apply_watermarks.py

"""

import os
import sys
import io
import django

# Initialisation Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')
django.setup()

from PIL import Image
from django.conf import settings
from django.core.files.base import ContentFile
from logersn.models import PropertyImage

# ─────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────
WATERMARK_PATH = os.path.join(settings.BASE_DIR, 'static', 'img', 'icon-192x192.png')
WATERMARK_OPACITY = 0.25    # 25% — très subtil et pro
WATERMARK_SIZE_RATIO = 0.20  # 20% de la largeur (discret, centré)
WEBP_QUALITY = 85


def apply_watermark(img: Image.Image) -> Image.Image:
    """Applique le texte 'www.logersenegal.com' centré sur l'image."""
    from PIL import ImageDraw, ImageFont

    img_rgba = img.convert("RGBA")
    make_watermark = Image.new("RGBA", img_rgba.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(make_watermark)

    text = "www.logersenegal.com"
    
    # Taille proportionnelle (5% de la largeur)
    font_size = int(img_rgba.width * 0.05)
    
    # Fonts linux
    try:
        font_paths = [
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/usr/share/fonts/liberation/LiberationSans-Bold.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
        ]
        font = None
        for path in font_paths:
            if os.path.exists(path):
                font = ImageFont.truetype(path, font_size)
                break
        if not font: font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()

    # Position
    try:
        left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
        text_width, text_height = right - left, bottom - top
    except:
        text_width, text_height = draw.textsize(text, font=font)

    x, y = (img_rgba.width - text_width) // 2, (img_rgba.height - text_height) // 2

    # Blanc à 25% (60/255)
    draw.text((x, y), text, font=font, fill=(255, 255, 255, 60))

    watermarked = Image.alpha_composite(img_rgba, make_watermark)
    return watermarked.convert("RGB")


def process_all_images():
    if not os.path.exists(WATERMARK_PATH):
        print(f"❌ Erreur : Logo introuvable à {WATERMARK_PATH}")
        sys.exit(1)

    images = PropertyImage.objects.all()
    total = images.count()

    print(f"\n🚀 Loger Sénégal — Migration Filigrane")
    print(f"   {total} image(s) à traiter...\n")

    success = 0
    skipped = 0
    errors = 0

    for i, prop_img in enumerate(images, start=1):
        try:
            if not prop_img.image_url or not prop_img.image_url.name:
                skipped += 1
                continue

            file_path = prop_img.image_url.path

            if not os.path.exists(file_path):
                print(f"  [{i}/{total}] ⚠️  Fichier manquant : {prop_img.image_url.name}")
                skipped += 1
                continue

            # Lecture de l'image
            with Image.open(file_path) as img:
                if img.mode in ("RGBA", "P"):
                    img = img.convert("RGB")

                # Redimensionnement si nécessaire
                max_width = 1200
                if img.width > max_width:
                    output_size = (max_width, int((max_width / img.width) * img.height))
                    img = img.resize(output_size, Image.LANCZOS)

                # Application du filigrane
                img_watermarked = apply_watermark(img)

                # Sauvegarde en WebP
                output = io.BytesIO()
                img_watermarked.save(output, format='WEBP', quality=WEBP_QUALITY)
                output.seek(0)

                # Forcer le nom en .webp
                base_name = os.path.splitext(prop_img.image_url.name)[0]
                new_name = f"{base_name}.webp"

                prop_img.image_url.save(new_name, ContentFile(output.read()), save=False)
                prop_img.save(update_fields=['image_url'])

            print(f"  [{i}/{total}] ✅ {prop_img.image_url.name}")
            success += 1

        except Exception as e:
            print(f"  [{i}/{total}] ❌ Erreur sur image ID={prop_img.id} : {e}")
            errors += 1

    print(f"\n{'─'*50}")
    print(f"✅ Succès  : {success}")
    print(f"⚠️  Ignorés : {skipped}")
    print(f"❌ Erreurs : {errors}")
    print(f"{'─'*50}")
    print("Migration terminée.\n")


if __name__ == '__main__':
    process_all_images()
