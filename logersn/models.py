import uuid
import io
import os
from PIL import Image
from django.core.files.base import ContentFile
from django.db import models
from django.urls import reverse
from django.utils.text import slugify
from django.conf import settings

User = settings.AUTH_USER_MODEL

from .constants import PROPERTY_TYPE_CHOICES, CITY_CHOICES, NEIGHBORHOOD_CHOICES

class Property(models.Model):
    class CategoryEnum(models.TextChoices):
        RENT = 'RENT', 'A louer'
        SALE = 'SALE', 'A vendre'
        FURNISHED = 'FURNISHED', 'Meublé'

    class DocumentTypeEnum(models.TextChoices):
        BAIL = 'BAIL', 'BAIL'
        TITRE_FONCIER_INDIVIDUEL = 'TITRE_FONCIER_INDIVIDUEL', 'TITRE FONCIER INDIVIDUEL'
        TITRE_FONCIER_GLOBAL = 'TITRE_FONCIER_GLOBAL', 'TITRE FONCIER GLOBAL'
        ACTE_DE_VENTE = 'ACTE_DE_VENTE', 'ACTE DE VENTE'
        DELIBERATION = 'DELIBERATION', 'DELIBERATION'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='properties')
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True, null=True, blank=True)
    description = models.TextField()
    listing_category = models.CharField(max_length=20, choices=CategoryEnum.choices, default=CategoryEnum.RENT)
    property_type = models.CharField(max_length=50, choices=PROPERTY_TYPE_CHOICES)
    city = models.CharField(max_length=100, choices=CITY_CHOICES, default='DAKAR')
    neighborhood = models.CharField(max_length=100)
    document_type = models.CharField(max_length=50, choices=DocumentTypeEnum.choices, null=True, blank=True, verbose_name="Type de document")
    price = models.DecimalField(max_digits=20, decimal_places=2, verbose_name="Prix (CFA)")
    
    # Promotions DigitalH
    promo_price = models.DecimalField(max_digits=20, decimal_places=2, null=True, blank=True, verbose_name="Prix Promotionnel (CFA)")
    promo_description = models.CharField(max_length=255, null=True, blank=True, verbose_name="Texte de promotion (ex: -10% ce weekend)")
    is_on_promotion = models.BooleanField(default=False, verbose_name="Afficher en promotion")

    
    # Pour les meublés uniquement
    price_per_night = models.DecimalField(max_digits=20, decimal_places=2, null=True, blank=True, verbose_name="Prix par nuitée (Meublé)")
    surface = models.IntegerField(default=0, blank=True, verbose_name="Surface (m2)")
    bedrooms = models.IntegerField(default=0, blank=True, verbose_name="Nombre de chambres")
    toilets = models.IntegerField(default=0, blank=True, verbose_name="Nombre de toilettes")
    total_rooms = models.IntegerField(default=1, blank=True, verbose_name="Nombre total de pièces")
    floor_level = models.IntegerField(default=0, blank=True, verbose_name="Niveau d'étage")
    has_garage = models.BooleanField(default=False, blank=True, verbose_name="Garage disponible")
    # Nouvelles pièces
    salons = models.IntegerField(default=0, blank=True, verbose_name="Nombre de salons")
    kitchens = models.IntegerField(default=0, blank=True, verbose_name="Nombre de cuisines")
    
    # Nouveaux extérieurs
    has_balcony = models.BooleanField(default=False, blank=True, verbose_name="Balcon")
    has_terrace = models.BooleanField(default=False, blank=True, verbose_name="Terrasse")
    has_courtyard = models.BooleanField(default=False, blank=True, verbose_name="Cour")
    has_garden = models.BooleanField(default=False, blank=True, verbose_name="Jardin")
    
    is_published = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True, verbose_name="En ligne") # Pour gérer les annonces retirées
    
    # DigitalH Pro Features (Confidentiel)
    internal_ref = models.CharField(max_length=100, blank=True, null=True, verbose_name="Référence Interne (Pro)")
    private_contact_info = models.TextField(blank=True, null=True, verbose_name="Infos Contact Privé (Pro)")
    
    # Équipements et caractéristiques (Amenities)
    wifi = models.BooleanField(default=False, verbose_name="WiFi")
    swimming_pool = models.BooleanField(default=False, verbose_name="Piscine")
    gym = models.BooleanField(default=False, verbose_name="Salle de sport")
    air_conditioning = models.BooleanField(default=False, verbose_name="Climatisation")
    refrigerator = models.BooleanField(default=False, verbose_name="Réfrigérateur")
    washing_machine = models.BooleanField(default=False, verbose_name="Machine à laver")
    microwave = models.BooleanField(default=False, verbose_name="Micro-ondes")
    tv_cable = models.BooleanField(default=False, verbose_name="TV par câble")
    generator = models.BooleanField(default=False, verbose_name="Groupe électrogène")
    water_tank = models.BooleanField(default=False, verbose_name="Réservoir d'eau")
    has_elevator = models.BooleanField(default=False, verbose_name="Ascenseur")
    has_security = models.BooleanField(default=False, verbose_name="Sécurité 24/7")
    has_concierge = models.BooleanField(default=False, verbose_name="Service de conciergerie")
    
    # Géolocalisation
    latitude = models.DecimalField(max_digits=15, decimal_places=10, null=True, blank=True)
    longitude = models.DecimalField(max_digits=15, decimal_places=10, null=True, blank=True)
    
    # Vidéo Externe (YouTube / TikTok)
    video_url = models.URLField(max_length=500, blank=True, null=True, verbose_name="Lien Vidéo (YouTube ou TikTok)")

    # Statistiques et Performance
    views_count = models.PositiveIntegerField(default=0, verbose_name="Nombre de vues")
    boosted_views_count = models.PositiveIntegerField(default=0, verbose_name="Nombre de vues (Boost)")
    clicks_count = models.PositiveIntegerField(default=0, verbose_name="Nombre de clics d'action")

    # Options de Monétisation DigitalH
    is_boosted = models.BooleanField(default=False, verbose_name="Annonce Boostée")
    boost_until = models.DateTimeField(null=True, blank=True, verbose_name="Boost valide jusqu'au")
    
    class StatusEnum(models.TextChoices):
        NONE = 'NONE', 'Aucun'
        PENDING = 'PENDING', 'En attente de validation'
        ACTIVE = 'ACTIVE', 'Actif'
        EXPIRED = 'EXPIRED', 'Expiré'

    boost_status = models.CharField(max_length=20, choices=StatusEnum.choices, default=StatusEnum.NONE)
    popup_status = models.CharField(max_length=20, choices=StatusEnum.choices, default=StatusEnum.NONE)

    is_featured_popup = models.BooleanField(default=False, verbose_name="Mise en avant Pop-up")
    popup_until = models.DateTimeField(null=True, blank=True, verbose_name="Pop-up valide jusqu'au")

    is_paid = models.BooleanField(default=False, verbose_name="Frais de publication payés")
    
    # Champ de communication Admin -> Pro
    admin_note = models.TextField(blank=True, null=True, verbose_name="Note de l'administrateur (Sera envoyée au propriétaire)")
    
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title

    def get_absolute_url(self):
        if self.slug:
            return reverse('property_detail_slug', kwargs={'slug': self.slug})
        return reverse('property_detail', kwargs={'property_id': self.id})

    def save(self, *args, **kwargs):
        is_new = self._state.adding
        # On détecte si la note admin a changé (pour ne pas spammer)
        old_note = None
        if not is_new:
            try:
                # Utiliser .only pour la performance lors du check
                old_instance = Property.objects.filter(pk=self.pk).only('admin_note').first()
                if old_instance:
                    old_note = old_instance.admin_note
            except Exception:
                pass

        if not self.slug or self.slug.startswith('propriete-'):
            from django.utils.text import slugify
            base_slug = slugify(self.title)
            if not base_slug:
                base_slug = "propriete"
            # On ajoute une partie de l'ID pour garantir l'unicité absolue
            self.slug = f"{base_slug}-{str(self.id)[:8]}"
            
        super().save(*args, **kwargs)

        # Notification automatique si l'admin a écrit une note
        if self.admin_note and self.admin_note != old_note:
            if self.owner.email:
                try:
                    import threading
                    from logersenegal.emails import send_property_update_notification
                    # Utiliser un thread pour ne pas bloquer le save() et fixer la lenteur de soumission
                    thread = threading.Thread(target=send_property_update_notification, args=(self, self.admin_note))
                    thread.start()
                except Exception as e:
                    print(f"Erreur notification admin_note: {e}")

    def get_main_image(self):
        primary_image = self.images.filter(is_primary=True).first()
        if primary_image:
            return primary_image
        return self.images.first()
        
    def get_icon_class(self):
        t = self.property_type or ''
        if 'APARTMENT' in t:
            return 'fa-building'
        if 'STUDIO' in t:
            return 'fa-door-open'
        if 'MAISON' in t or 'VILLA' in t:
            return 'fa-house'
        if 'TERRAIN' in t:
            return 'fa-mountain-sun'
        if 'COMMERCIAL' in t or 'BOUTIQUE' in t or 'MAGASIN' in t:
            return 'fa-shop'
        if 'BUREAU' in t:
            return 'fa-briefcase'
        return 'fa-building'

class PropertyImage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    property = models.ForeignKey(Property, on_delete=models.CASCADE, related_name='images')
    image_url = models.FileField(upload_to='properties/')
    is_primary = models.BooleanField(default=False)

    def save(self, *args, **kwargs):
        """Conversion automatique en WebP et redimensionnement intelligent (Sécurisé)."""
        if self.image_url:
            try:
                # On ne tente la conversion que si Pillow est disponible et le fichier n'est pas déjà webp
                if not self.image_url.name.lower().endswith('.webp'):
                    img = Image.open(self.image_url)
                    
                    # 1. Conversion en RGB
                    if img.mode in ("RGBA", "P"):
                        img = img.convert("RGB")
                    
                    # 2. Redimensionnement
                    max_width = 1200
                    if img.width > max_width:
                        output_size = (max_width, int((max_width / img.width) * img.height))
                        img = img.resize(output_size, Image.LANCZOS)
                    
                    # 3. Flux mémoire
                    output = io.BytesIO()
                    img.save(output, format='WEBP', quality=85)
                    output.seek(0)
                    
                    # 4. Changement de nom et sauvegarde du champ
                    current_name = os.path.splitext(self.image_url.name)[0]
                    new_filename = f"{current_name}.webp"
                    self.image_url.save(new_filename, ContentFile(output.read()), save=False)
            except Exception as e:
                # En cas d'erreur (PIL manquant, erreur de format, etc.), on ignore et on garde l'original
                print(f"WebP conversion failed for {self.image_url.name}: {e}")
            
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Image for {self.property.title}"

class Transaction(models.Model):
    class TypeEnum(models.TextChoices):
        PUBLICATION = 'PUBLICATION', 'Frais de Publication'
        BOOST = 'BOOST', 'Boost d\'Annonce'
        POPUP = 'POPUP', 'Mise en avant Pop-up'

    class BoostType(models.TextChoices):
        NONE = 'NONE', 'Aucun'
        FEED = 'FEED', 'In-Feed (Liste)'
        SLIDER = 'SLIDER', 'Slider (Accueil)'
        POPUP = 'POPUP', 'Pop-up Premium'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='transactions')
    property = models.ForeignKey(Property, on_delete=models.SET_NULL, null=True, blank=True, related_name='transactions')
    transaction_type = models.CharField(max_length=20, choices=TypeEnum.choices)
    boost_type = models.CharField(max_length=20, choices=BoostType.choices, default=BoostType.NONE)
    amount = models.DecimalField(max_digits=20, decimal_places=2)
    reference = models.CharField(max_length=100, unique=True, verbose_name="Référence FedaPay / Interne")
    status = models.CharField(max_length=20, choices=[('PENDING', 'En attente'), ('SUCCESS', 'Réussite'), ('FAILED', 'Échec')], default='PENDING')
    days = models.IntegerField(default=1, verbose_name="Nombre de jours")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Transaction"
        verbose_name_plural = "Transactions (Comptabilité)"

    def __str__(self):
        return f"{self.user} - {self.transaction_type} - {self.amount}F"

class PricingConfig(models.Model):
    publication_fee_rent = models.DecimalField(max_digits=20, decimal_places=2, default=100.00, verbose_name="Prix Publication (Location)")
    publication_fee_sale = models.DecimalField(max_digits=20, decimal_places=2, default=500.00, verbose_name="Prix Publication (Vente)")
    publication_fee_furnished = models.DecimalField(max_digits=20, decimal_places=2, default=300.00, verbose_name="Prix Publication (Meublé)")
    
    # Boosts
    boost_daily_fee = models.DecimalField(max_digits=20, decimal_places=2, default=100.00, verbose_name="Prix Boost In-Feed par jour")
    boost_slider_fee = models.DecimalField(max_digits=20, decimal_places=2, default=200.00, verbose_name="Prix Boost Slider par jour")
    popup_daily_fee = models.DecimalField(max_digits=20, decimal_places=2, default=500.00, verbose_name="Prix Pop-up par jour")

    class Meta:
        verbose_name = "Paramètres des Tarifs"
        verbose_name_plural = "Paramètres des Tarifs (DigitalH)"

    def __str__(self):
        return "Configuration des tarifs DigitalH"

class Favorite(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorites')
    property = models.ForeignKey(Property, on_delete=models.CASCADE, related_name='favorited_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'property')

    def __str__(self):
        return f"{self.user} favorited {self.property}"

class PropertyEquipment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    property = models.ForeignKey(Property, on_delete=models.CASCADE, related_name='interior_equipments')
    name = models.CharField(max_length=100, help_text="Ex: Réfrigérateur, Climatiseur, TV...")
    brand = models.CharField(max_length=100, blank=True, null=True, help_text="Marque optionnelle")
    icon_class = models.CharField(max_length=50, default='fa-plug', help_text="Icône FontAwesome (ex: fa-tv, fa-snowflake)")
    
    def __str__(self):
        return f"{self.name} for {self.property.title}"
