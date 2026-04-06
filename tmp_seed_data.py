import os
import django
import uuid
from decimal import Decimal
from django.utils import timezone
import datetime

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'logersenegal.settings')
django.setup()

from users.models import User, NILS_Profile
from solvable.models import RentalFiliation, IncidentReport, PaymentHistory
from logersn.models import Property

def seed():
    print("--- Démarrage du Seeding Solvable ---")
    
    # 1. Création des Professionnels (Bailleur & Courtier)
    landlord, _ = User.objects.get_or_create(
        phone_number="770000001",
        defaults={
            "first_name": "Moussa",
            "last_name": "Bailleur",
            "role": "LANDLORD",
            "is_verified_pro": True,
            "is_phone_verified": True
        }
    )
    landlord.set_password("pass1234")
    landlord.save()

    broker, _ = User.objects.get_or_create(
        phone_number="770000002",
        defaults={
            "first_name": "Fatou",
            "last_name": "Courtier",
            "role": "BROKER",
            "is_verified_pro": True,
            "is_phone_verified": True,
            "company_name": "Elite Immo Sénégal"
        }
    )
    broker.set_password("pass1234")
    broker.save()

    # 2. Création des Locataires (Bons et Mauvais)
    
    # LE BON PAYEUR
    good_user, _ = User.objects.get_or_create(
        phone_number="771112233",
        defaults={
            "first_name": "Abdou",
            "last_name": "Sarr",
            "role": "TENANT",
            "cni_number": "1234567890123",
            "employer": "Orange Sénégal (Cadre)",
            "marital_status": "Marié"
        }
    )
    good_user.set_password("pass1234")
    good_user.save()
    
    good_profile, _ = NILS_Profile.objects.get_or_create(user=good_user)
    good_profile.score = 98
    good_profile.reputation_status = 'GREEN'
    good_profile.save()

    # LE MAUVAIS PAYEUR (Loyers impayés)
    bad_user1, _ = User.objects.get_or_create(
        phone_number="774445566",
        defaults={
            "first_name": "Ibrahima",
            "last_name": "Diop",
            "role": "TENANT",
            "cni_number": "9876543210987",
            "employer": "Indépendant",
            "marital_status": "Célibataire"
        }
    )
    bad_user1.save()
    bad_profile1, _ = NILS_Profile.objects.get_or_create(user=bad_user1)
    
    # LE MAUVAIS PAYEUR (Commission impayée + Changement d'identité partiel)
    bad_user2, _ = User.objects.get_or_create(
        phone_number="778889900",
        defaults={
            "first_name": "Mariama",
            "last_name": "Faye",
            "role": "TENANT",
            "cni_number": "5556667778881",
            "employer": "Commerciale",
            "marital_status": "Mariée",
            "spouse_name": "Jean Faye"
        }
    )
    bad_user2.save()
    bad_profile2, _ = NILS_Profile.objects.get_or_create(user=bad_user2)

    # 3. Création des Incidents
    
    # Une propriété fictive pour le lien
    prop, _ = Property.objects.get_or_create(
        title="Appartement Test Seeding",
        defaults={
            "owner": landlord,
            "property_type": "Appartement",
            "city": "Dakar",
            "price": 250000,
            "is_certified": True
        }
    )

    # Filiation pour Bad User 1 (Loyers)
    filiation1, _ = RentalFiliation.objects.get_or_create(
        landlord=landlord,
        tenant=bad_user1,
        property=prop,
        defaults={"monthly_rent": 250000, "start_date": timezone.now().date()}
    )
    filiation1.status = 'ACTIVE'
    filiation1.save()

    # Déclaration d'un loyer impayé
    IncidentReport.objects.get_or_create(
        rental_filiation=filiation1,
        reported_tenant=bad_user1,
        reporter=landlord,
        incident_type='UNPAID_RENT',
        defaults={
            "amount_due": 500000,
            "description": "Deux mois de loyer non payés. Le locataire ne répond plus.",
            "status": 'IMPACTED'
        }
    )
    
    # Filiation pour Bad User 2 (Commission Courtier)
    filiation2, _ = RentalFiliation.objects.get_or_create(
        landlord=landlord, # Le courtier agit sur un contrat existant ou lié
        tenant=bad_user2,
        property=prop,
        defaults={"monthly_rent": 300000, "start_date": timezone.now().date()}
    )
    
    IncidentReport.objects.get_or_create(
        rental_filiation=filiation2,
        reported_tenant=bad_user2,
        reporter=broker, # C'est le courtier qui signale !
        incident_type='UNPAID_COMMISSION',
        defaults={
            "amount_due": 150000,
            "description": "Commission de courtage non versée après signature du bail.",
            "status": 'IMPACTED'
        }
    )

    # Mise à jour des scores par calcul
    bad_profile1.update_score()
    bad_profile2.update_score()
    
    print("--- Seeding terminé avec succès ---")
    print(f"Bons payeurs créés: {good_user.phone_number} (Score: {good_profile.score})")
    print(f"Mauvais payeurs créés (Incident Loyer): {bad_user1.phone_number} (Score: {bad_profile1.score})")
    print(f"Mauvais payeurs créés (Incident Commission): {bad_user2.phone_number} (Score: {bad_profile2.score})")

if __name__ == "__main__":
    seed()
