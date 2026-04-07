from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import PaymentHistory, IncidentReport

@receiver(post_save, sender=PaymentHistory)
@receiver(post_delete, sender=PaymentHistory)
def update_nils_on_payment_change(sender, instance, **kwargs):
    if instance.rental_filiation and instance.rental_filiation.tenant:
        tenant = instance.rental_filiation.tenant
        if hasattr(tenant, 'nils_profile'):
            tenant.nils_profile.update_score()

@receiver(post_save, sender=IncidentReport)
@receiver(post_delete, sender=IncidentReport)
def update_nils_on_incident_change(sender, instance, **kwargs):
    if instance.reported_tenant:
        reported_tenant = instance.reported_tenant
        if hasattr(reported_tenant, 'nils_profile'):
            reported_tenant.nils_profile.update_score()

from .models import RentalFiliation
@receiver(post_save, sender=RentalFiliation)
def update_nils_on_filiation_change(sender, instance, **kwargs):
    """Updates score when a filiation rating is added or status changes."""
    if instance.tenant and hasattr(instance.tenant, 'nils_profile'):
        instance.tenant.nils_profile.update_score()
    if instance.landlord and hasattr(instance.landlord, 'nils_profile'):
        instance.landlord.nils_profile.update_score()
