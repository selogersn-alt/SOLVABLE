import os
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersn.settings')
django.setup()

from users.models import User
from django.db import transaction

def migrate_phones():
    users = User.objects.all()
    updated_count = 0
    errors = 0

    print(f"Démarrage de la migration pour {users.count()} utilisateurs...")

    with transaction.atomic():
        for user in users:
            old_phone = user.phone_number.strip()
            
            # Si le numéro commence déjà par +, on ne touche pas
            if old_phone.startswith('+'):
                continue
            
            # Si le numéro fait 9 chiffres (format Sénégal standard sans indicatif)
            # Ou s'il commence par 7 (format habituel)
            if len(old_phone) >= 7:
                new_phone = f"+221{old_phone}"
                
                # Vérifier si le nouveau numéro n'existe pas déjà (sécurité doublons)
                if User.objects.filter(phone_number=new_phone).exists():
                    print(f"⚠️ Alerte : Le numéro {new_phone} existe déjà. Saut de l'utilisateur {user.id}")
                    errors += 1
                    continue
                
                user.phone_number = new_phone
                user.save()
                updated_count += 1
                # print(f"✅ Migré : {old_phone} -> {new_phone}")

    print(f"\n--- Migration terminée ---")
    print(f"Total mis à jour : {updated_count}")
    print(f"Erreurs/Doublons : {errors}")

if __name__ == "__main__":
    migrate_phones()
