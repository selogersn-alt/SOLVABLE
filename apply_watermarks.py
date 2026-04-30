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
    """Applique le filigrane centré sur l'image."""
    watermark = Image.open(WATERMARK_PATH).convert("RGBA")

    # Redimensionnement proportionnel
    wm_width = int(img.width * WATERMARK_SIZE_RATIO)
    wm_ratio = wm_width / watermark.width
    wm_height = int(watermark.height * wm_ratio)
    watermark = watermark.resize((wm_width, wm_height), Image.LANCZOS)

    # Opacité
    r, g, b, a = watermark.split()
    a = a.point(lambda p: int(p * WATERMARK_OPACITY))
    watermark.putalpha(a)

    # Fusion — position CENTRE
    img_rgba = img.convert("RGBA")
    x = (img_rgba.width - wm_width) // 2
    y = (img_rgba.height - wm_height) // 2

    overlay = Image.new("RGBA", img_rgba.size, (0, 0, 0, 0))
    overlay.paste(watermark, (x, y))
    watermarked = Image.alpha_composite(img_rgba, overlay)

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
