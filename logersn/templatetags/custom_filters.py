from django import template

register = template.Library()

@register.filter(name='format_price')
def format_price(value):
    """
    Formatte un nombre avec un espace comme séparateur de milliers.
    Exemple: 1000000 -> 1 000 000
    """
    if value is None:
        return ""
    try:
        # Convertir en entier pour enlever les décimales inutiles (.0)
        value = int(float(value))
        # Utiliser le formatage f-string avec espace comme séparateur
        return "{:,}".format(value).replace(",", " ")
    except (ValueError, TypeError):
        return value
