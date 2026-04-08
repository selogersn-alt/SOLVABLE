from django.contrib.sitemaps import Sitemap
from django.urls import reverse
from .models import Property

class PropertySitemap(Sitemap):
    changefreq = "daily"
    priority = 0.9

    def items(self):
        # On indexe tous les biens immobiliers
        return Property.objects.all().order_by('-created_at')

    def lastmod(self, obj):
        return obj.updated_at

    def location(self, obj):
        # URL vers la page de détails du bien
        return f"/properties/{obj.id}/"

class StaticViewSitemap(Sitemap):
    priority = 0.5
    changefreq = 'weekly'

    def items(self):
        # On peut ajouter ici les noms de vos URLs de base
        # Assurez-vous qu'elles existent dans vos urls.py
        return ['home'] 

    def location(self, item):
        return reverse(item)
