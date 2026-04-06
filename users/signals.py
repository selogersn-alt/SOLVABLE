from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import KYCProfile, NILS_Profile

@receiver(post_save, sender=KYCProfile)
def create_nils_on_kyc_approval(sender, instance, **kwargs):
    # Si le profil KYC passe au statut APPROVED, on crée le profil NILS automatiquement
    if instance.vision_api_status == KYCProfile.StatusEnum.APPROVED:
        # On crée le profil NILS correspondant au rôle de l'utilisateur s'il n'existe pas encore
        if not instance.user.nils_profiles.filter(nils_type=instance.user.role).exists():
            NILS_Profile.objects.create(user=instance.user, nils_type=instance.user.role)
