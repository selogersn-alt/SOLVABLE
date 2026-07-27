import os
import sys
import django
import shutil
import re

# 1. Initialiser Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')
django.setup()

from logersn.models import PropertyImage
from articles.models import BlogPost
from users.models import User
from django.conf import settings

def clean_path(name):
    if not name:
        return name
        
    old_name = name
    # Supprimer les domaines absolus et schémas
    name = re.sub(r'^https?://(www\.)?logersn\.com/', '', name)
    name = re.sub(r'^https?://(www\.)?logersenegal\.com/', '', name)
    
    # Retirer le slash de début pour en faire un chemin relatif valide sous media/
    if name.startswith('/'):
        name = name.lstrip('/')
        
    return name

def fix_migration():
    print("=== Démarrage de la correction des images de migration ===")
    
    # --- ETAPE 1 : Organisation des dossiers physiques ---
    # On vérifie si un dossier 'wp-content' existe à la racine du projet
    root_wp = os.path.join(settings.BASE_DIR, 'wp-content')
    media_wp = os.path.join(settings.MEDIA_ROOT, 'wp-content')
    
    if os.path.exists(root_wp) and not os.path.exists(media_wp):
        print(f"📁 Dossier 'wp-content' trouvé à la racine. Déplacement vers le dossier media...")
        try:
            shutil.move(root_wp, media_wp)
            print("✅ Déplacement réussi !")
        except Exception as e:
            print(f"❌ Erreur lors du déplacement : {e}")
            print("Tentative de création d'un lien symbolique à la place...")
            try:
                os.symlink(root_wp, media_wp, target_is_directory=True)
                print("✅ Lien symbolique créé avec succès !")
            except Exception as se:
                print(f"❌ Échec de la création du lien symbolique : {se}")
    else:
        print("ℹ️ Pas de dossier 'wp-content' à déplacer à la racine (ou déjà présent dans media).")

    # --- ETAPE 2 : Nettoyage de la base de données ---
    
    # 2.1. Table PropertyImage
    updated_prop_images = 0
    for img in PropertyImage.objects.all():
        if img.image_url and img.image_url.name:
            new_name = clean_path(img.image_url.name)
            if new_name != img.image_url.name:
                PropertyImage.objects.filter(pk=img.pk).update(image_url=new_name)
                updated_prop_images += 1
                print(f"   [PropertyImage] {img.image_url.name} ➔ {new_name}")
                
    # 2.2. Table BlogPost
    updated_blog_posts = 0
    for post in BlogPost.objects.all():
        if post.image and post.image.name:
            new_name = clean_path(post.image.name)
            if new_name != post.image.name:
                BlogPost.objects.filter(pk=post.pk).update(image=new_name)
                updated_blog_posts += 1
                print(f"   [BlogPost] {post.image.name} ➔ {new_name}")
                
    # 2.3. Table User
    updated_users = 0
    for user in User.objects.all():
        if user.profile_picture and user.profile_picture.name:
            new_name = clean_path(user.profile_picture.name)
            if new_name != user.profile_picture.name:
                User.objects.filter(pk=user.pk).update(profile_picture=new_name)
                updated_users += 1
                print(f"   [User] {user.profile_picture.name} ➔ {new_name}")
                
    print(f"\n=== Résumé de la mise à jour ===")
    print(f"📸 Images d'annonces mises à jour : {updated_prop_images}")
    print(f"📰 Images de blog mises à jour     : {updated_blog_posts}")
    print(f"👤 Photos de profil mises à jour   : {updated_users}")
    print(f"=================================")

if __name__ == '__main__':
    fix_migration()
