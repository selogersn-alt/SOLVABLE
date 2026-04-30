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
    images = PropertyImage.objects.all()
    total = images.count()

    print(f"\n🔄 Restauration des images originales...")
    print(f"   {total} image(s) à vérifier...\n")

    restored = 0
    not_found = 0

    for i, prop_img in enumerate(images, start=1):
        if not prop_img.image_url:
            continue

        current_path = prop_img.image_url.path
        current_name = prop_img.image_url.name

        # On ne s'intéresse qu'aux fichiers .webp qui ont pu être filigranés
        if current_name.lower().endswith('.webp'):
            base_path = os.path.splitext(current_name)[0]
            
            # Extensions possibles pour l'original
            possible_extensions = ['.jpg', '.jpeg', '.png', '.JPG', '.PNG']
            found_original = None

            for ext in possible_extensions:
                test_path = base_path + ext
                full_test_path = os.path.join(settings.MEDIA_ROOT, test_path)
                
                if os.path.exists(full_test_path):
                    found_original = test_path
                    break
            
            if found_original:
                print(f"  [{i}/{total}] ✅ Restauration : {found_original}")
                # Supprimer le webp "sale"
                if os.path.exists(current_path):
                    os.remove(current_path)
                
                # Mettre à jour la base de données vers l'original
                prop_img.image_url.name = found_original
                prop_img.save(update_fields=['image_url'])
                restored += 1
            else:
                print(f"  [{i}/{total}] ⚠️ Original introuvable pour {current_name}")
                not_found += 1
        else:
            # Déjà un JPG ou PNG
            pass

    print(f"\n{'─'*50}")
    print(f"✅ Restaurées : {restored}")
    print(f"⚠️  Inchangées : {not_found}")
    print(f"{'─'*50}\n")

if __name__ == '__main__':
    from django.conf import settings
    restore_originals()
