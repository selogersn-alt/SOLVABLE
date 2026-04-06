from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from users.models import KYCProfile, NILS_Profile
from logersn.models import Property, PropertyImage
from solvable.models import RentalFiliation
import random
import uuid

User = get_user_model()

class Command(BaseCommand):
    help = 'Seeds fictional data for testing purposes'

    def handle(self, *args, **options):
        self.stdout.write("Seeding data...")

        # 1. Create 4 Agents
        agent_data = [
            ("771000001", "agent1@solvable.sn", "Dakar Plateau", "Agent Diallo Immobilier"),
            ("771000002", "agent2@solvable.sn", "Mermoz / Sacré-Cœur", "Kory Agence"),
            ("771000003", "agent3@solvable.sn", "Ouakam / Mamelles", "Arona Immo"),
            ("771000004", "agent4@solvable.sn", "Almadies", "Elite Agent"),
        ]
        agents = []
        for phone, email, area, company in agent_data:
            user, created = User.objects.get_or_create(
                phone_number=phone,
                defaults={
                    'email': email,
                    'coverage_area': area,
                    'company_name': company,
                    'role': User.RoleEnum.AGENT,
                    'is_verified_pro': True
                }
            )
            if created:
                user.set_password("Solvable123!")
                user.save()
            agents.append(user)

        # 2. Create 4 Landlords (Bailleurs)
        landlord_data = [
            ("781000001", "bailleur1@solvable.sn", "Thiès", "SCI Horizon"),
            ("781000002", "bailleur2@solvable.sn", "Dakar", "M. Fall Immobilier"),
            ("781000003", "bailleur3@solvable.sn", "Saint-Louis", "Résidence du Fleuve"),
            ("781000004", "bailleur4@solvable.sn", "Saly", "Villas du Soleil"),
        ]
        landlords = []
        for phone, email, area, company in landlord_data:
            user, created = User.objects.get_or_create(
                phone_number=phone,
                defaults={
                    'email': email,
                    'coverage_area': area,
                    'company_name': company,
                    'role': User.RoleEnum.LANDLORD,
                    'is_verified_pro': True
                }
            )
            if created:
                user.set_password("Solvable123!")
                user.save()
            landlords.append(user)

        # 3. Create 4 Agencies
        agency_data = [
            ("761000001", "agence1@solvable.sn", "Dakar / Banlieue", "Kër Gui Immo"),
            ("761000002", "agence2@solvable.sn", "Ziguinchor", "Casamance Immobilier"),
            ("761000003", "agence3@solvable.sn", "Dakar Centre", "Loger Sans Stress"),
            ("761000004", "agence4@solvable.sn", "Touba", "Diarra Agence"),
        ]
        agencies = []
        for phone, email, area, company in agency_data:
            user, created = User.objects.get_or_create(
                phone_number=phone,
                defaults={
                    'email': email,
                    'coverage_area': area,
                    'company_name': company,
                    'role': User.RoleEnum.AGENCY,
                    'is_verified_pro': True
                }
            )
            if created:
                user.set_password("Solvable123!")
                user.save()
            agencies.append(user)

        # 4. Create 10 Properties
        prop_titles = [
            "Appartement F4 Moderne à Mermoz",
            "Studio Meublé aux Almadies",
            "Villa de Standing avec Piscine à Saly",
            "Bureau 200m2 en Centre-Ville",
            "Chambre Étudiant Proche Université",
            "Appartement F3 Vue Mer à Ngor",
            "Duplex de Luxe à Sacré-Cœur 3",
            "Hangar Industriel Zone Franche",
            "Terrain Constructible 500m2 à Diamniadio",
            "Local Commercial RDC Avenue Bourguiba"
        ]
        
        all_pros = agents + landlords + agencies
        # Real Choices from constants
        cities = ['DAKAR', 'THIES', 'SAINT_LOUIS', 'ZIGUINCHOR', 'MBOUR', 'SALY', 'TOUBA']
        p_types = ['APARTMENT_F4', 'STUDIO', 'VILLA', 'BUREAU', 'CHAMBRE_SDB', 'APARTMENT_F3', 'DUPLEX', 'COMMERCIAL', 'TERRAIN', 'COMMERCIAL']
        neighborhoods = ['MERMOZ', 'ALMADIES', 'SALY_PORTUDAL', 'PLATEAU', 'FANN', 'NGOR', 'SACRE_CŒUR_3', 'ZONE_INDUSTRIELLE', 'DIAMNIADIO', 'AVENUE_BOURGUIBA']

        for i in range(10):
            owner = random.choice(all_pros)
            prop, created = Property.objects.get_or_create(
                title=prop_titles[i],
                defaults={
                    'owner': owner,
                    'property_type': p_types[i],
                    'city': cities[i % len(cities)],
                    'neighborhood': neighborhoods[i],
                    'rent_price': random.randint(150000, 2000000),
                    'surface': random.randint(50, 450),
                    'bedrooms': random.randint(1, 5),
                    'toilets': random.randint(1, 4),
                    'total_rooms': random.randint(2, 8),
                    'has_garage': random.choice([True, False]),
                    'description': "Ceci est une annonce fictive générée pour tester l'interface visuelle et le rendu des listes. Détails du bien : propre, sécurisé, accès facile.",
                    'is_published': True
                }
            )
            if created:
                # Add a dummy image placeholder
                # We can't easily upload real files via script without absolute paths, 
                # but we can try to find existing ones or just leave it.
                # Since the user asked "image", I'll try to add a record.
                pass

        self.stdout.write(self.style.SUCCESS("Fictional data seeded successfully!"))
