from django.contrib.sitemaps import Sitemap
from django.urls import reverse
from .models import Property

class StaticViewSitemap(Sitemap):
    def items(self):
        return [
            'home', 
            'about', 
            'properties_list', 
            'professionals_list',
            'cgu',
            'privacy',
            'guide_locataires',
            'guide_bailleurs',
            'guide_agences',
            'guide_courtiers',
            'fraud_list'
        ]

    def priority(self, item):
        return 0.5

    def changefreq(self, item):
        return 'weekly'

    def location(self, item):
        try:
            return reverse(item)
        except:
            return "/"
