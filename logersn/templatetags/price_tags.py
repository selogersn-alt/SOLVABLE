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
