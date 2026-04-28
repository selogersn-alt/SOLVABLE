from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Property
from django.contrib.auth import get_user_model
from logersenegal.emails import send_admin_alert

User = get_user_model()

@receiver(post_save, sender=Property)
def notify_admin_new_property(sender, instance, created, **kwargs):
    if created:
        subject = f"🔔 Nouvelle annonce en attente : {instance.title}"
        message = f"Une nouvelle annonce a été créée par {instance.owner.phone_number}. Elle attend d'être validée pour passer en ligne."
        try:
            send_admin_alert(subject, message)
        except:
            pass

@receiver(post_save, sender=User)
def notify_admin_new_user(sender, instance, created, **kwargs):
    if created:
        subject = f"👤 Nouvel utilisateur inscrit : {instance.phone_number}"
        message = f"Un nouvel utilisateur vient de créer un compte avec le rôle : {instance.get_role_display()}."
        try:
            send_admin_alert(subject, message)
        except:
            pass
