from django import template
from django.contrib.humanize.templatetags.humanize import intcomma

register = template.Library()

@register.filter(name='clean_price')
def clean_price(value):
    """
    Force la conversion en entier et ajoute le séparateur de milliers.
    Ex: 1500000.00 -> 1 500 000
    """
    if value is None:
        return ""
    try:
        # On force en entier pour tuer les décimales
        integer_value = int(float(value))
        # On utilise intcomma pour le séparateur, qui respectera nos réglages settings.py
        return intcomma(integer_value)
    except (ValueError, TypeError):
        return value

@register.filter(name='embed_video')
def embed_video(url):
    """
    Transforme un lien YouTube ou TikTok en URL d'intégration (embed).
    """
    if not url:
        return None
    
    # YouTube
    if "youtube.com" in url or "youtu.be" in url:
        import re
        reg = r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})'
        match = re.search(reg, url)
        if match:
            # rel=0 limite les suggestions aux vidéos de la même chaîne à la fin
            return f"https://www.youtube.com/embed/{match.group(1)}?rel=0&autoplay=1"
            
    # TikTok
    if "tiktok.com" in url:
        import re
        # Extraction de l'ID vidéo TikTok (ex: /video/7123...)
        reg = r'video\/(\d+)'
        match = re.search(reg, url)
        if match:
            return f"https://www.tiktok.com/embed/v2/{match.group(1)}"
            
    return None
