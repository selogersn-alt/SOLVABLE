import os
import django
import uuid

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')
django.setup()

from users.models import User, NILS_Profile

def create_all_roles():
    roles_data = [
        {'role': 'TENANT', 'phone': '771000001', 'name': 'Lamine', 'last': 'Locataire'},
        {'role': 'LANDLORD', 'phone': '772000002', 'name': 'Abdou', 'last': 'Bailleur'},
        {'role': 'AGENCY', 'phone': '773000003', 'name': 'Elite', 'last': 'Immobilier', 'company': 'ELITE AGENCY SN'},
        {'role': 'BROKER', 'phone': '774000004', 'name': 'Fatou', 'last': 'Courtier'},
        {'role': 'AGENT', 'phone': '775000005', 'name': 'Modou', 'last': 'Agent'},
    ]
    
    password = "pass1234"
    
    print("--- Création des comptes de test multi-rôles ---")
    
    for data in roles_data:
        user, created = User.objects.get_or_create(
            phone_number=data['phone'],
            defaults={
                'first_name': data['name'],
                'last_name': data['last'],
                'role': data['role'],
                'company_name': data.get('company', ''),
                'is_verified_pro': data['role'] != 'TENANT',
                'is_phone_verified': True
            }
        )
        if created:
            user.set_password(password)
            user.save()
            print(f"✅ Créé : {data['name']} ({data['role']})")
        else:
            print(f"ℹ️ Existe déjà : {data['name']} ({data['role']})")
            
        # Assurer la présence d'un profil NILS
        nils, n_created = NILS_Profile.objects.get_or_create(
            user=user,
            defaults={'nils_type': data['role'], 'score': 100, 'reputation_status': 'GREEN'}
        )
        if n_created:
            print(f"   -> Profil NILS généré : {nils.nils_number}")
    
    print("--- Terminé. Tous les accès sont prêts. ---")

if __name__ == "__main__":
    create_all_roles()
