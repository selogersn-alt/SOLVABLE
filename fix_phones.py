import os
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersn.settings')
django.setup()

from users.models import User
from django.db import transaction

def fix_phones():
    users = User.objects.all()
    fixed_count = 0

    print(f"Démarrage de la réparation pour {users.count()} utilisateurs...")

    with transaction.atomic():
        for user in users:
            phone = user.phone_number.strip().replace(' ', '')
            original = phone
            
            # Cas 1 : Double indicatif +221221...
            if phone.startswith('+221221'):
                phone = '+' + phone[4:] # On garde le + et on enlève le premier 221
            
            # Cas 2 : Indicatif sans le + (ex: 22177...)
            elif phone.startswith('221') and not phone.startswith('+'):
                phone = '+' + phone
                
            # Cas 3 : Numéro à 9 chiffres sans rien (ex: 77...)
            elif len(phone) == 9 and phone[0] in ['7', '3']:
                phone = '+221' + phone

            if phone != original:
                # Vérifier les doublons avant de sauvegarder le fix
                if User.objects.filter(phone_number=phone).exclude(pk=user.pk).exists():
                    print(f"❌ Impossible de corriger {original} -> {phone} (Doublon détecté)")
                    continue
                
                user.phone_number = phone
                user.save()
                fixed_count += 1
                # print(f"✅ Corrigé : {original} -> {phone}")

    print(f"\n--- Réparation terminée ---")
    print(f"Total corrigés : {fixed_count}")

if __name__ == "__main__":
    fix_phones()
