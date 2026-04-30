"""
Script de restauration des images originales — Loger Sénégal
=============================================================
Ce script tente de restaurer les images originales (.jpg, .png)
pour annuler les filigranes appliqués de manière destructive
sur les fichiers .webp.

Utilisation :
    python restore_images.py
"""

import os
import sys
import django

# Initialisation Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')
django.setup()

from logersn.models import PropertyImage

def restore_originals():
    from django.conf import settings
    images = PropertyImage.objects.all()
    total = images.count()

    print(f"\n🔄 Nettoyage et Restauration des images...")
    print(f"   {total} image(s) en base de données...\n")

    restored = 0
    cleaned_path = 0

    for i, prop_img in enumerate(images, start=1):
        if not prop_img.image_url or not prop_img.image_url.name:
            continue

        # 1. Extraire uniquement le nom du fichier (nettoie les properties/properties/...)
        filename = os.path.basename(prop_img.image_url.name)
        base_name = os.path.splitext(filename)[0]
        
        # 2. Chercher l'original (jpg, png, etc.)
        possible_exts = ['.jpg', '.jpeg', '.png', '.JPG', '.PNG']
        found_original_filename = None
        
        for ext in possible_exts:
            test_filename = base_name + ext
            full_path = os.path.join(settings.MEDIA_ROOT, 'properties', test_filename)
            if os.path.exists(full_path):
                found_original_filename = test_filename
                break
        
        if found_original_filename:
            new_db_path = f"properties/{found_original_filename}"
            if prop_img.image_url.name != new_db_path:
                print(f"  [{i}/{total}] ✅ Restauration : {new_db_path}")
                # On utilise .update() pour ne PAS déclencher le save() du modèle
                PropertyImage.objects.filter(pk=prop_img.pk).update(image_url=new_db_path)
                restored += 1
        else:
            # Si c'est un webp sans original, on nettoie au moins le chemin
            new_db_path = f"properties/{filename}"
            if prop_img.image_url.name != new_db_path:
                print(f"  [{i}/{total}] 🧹 Nettoyage chemin : {new_db_path}")
                PropertyImage.objects.filter(pk=prop_img.pk).update(image_url=new_db_path)
                cleaned_path += 1

    print(f"\n{'─'*50}")
    print(f"✅ Restaurées (Originales) : {restored}")
    print(f"🧹 Chemins nettoyés       : {cleaned_path}")
    print(f"{'─'*50}\n")

if __name__ == '__main__':
    from django.conf import settings
    restore_originals()
