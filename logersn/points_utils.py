from django.db import transaction
from users.models import UserPoints, PointTransaction

def award_points(user, amount, action_type, description="", reference_id=None):
    """
    Distribue des points à un utilisateur de manière sécurisée.
    """
    try:
        with transaction.atomic():
            # Récupérer ou créer le solde de l'utilisateur
            points_balance, created = UserPoints.objects.get_or_create(user=user)
            
            # Créer la transaction
            PointTransaction.objects.create(
                user=user,
                amount=amount,
                action_type=action_type,
                description=description,
                reference_id=reference_id
            )
            
            # Mettre à jour le solde
            points_balance.balance += amount
            points_balance.save()
            
            print(f"Points attribués : {amount} à {user.phone_number} pour {action_type}")
            return True
    except Exception as e:
        print(f"Erreur lors de l'attribution des points : {str(e)}")
        return False

# Valeurs par défaut pour les actions
POINTS_VALUES = {
    'PROFILE_VALIDATION': 100,
    'PROPERTY_PUBLISHED': 50,
    'REFERRAL_SUCCESS': 200,
    'DAILY_LOGIN': 5,
}
