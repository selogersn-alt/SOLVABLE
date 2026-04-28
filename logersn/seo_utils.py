# SEO Mapping for Loger Sénégal
# Maps URL slugs to internal model choices

SEO_TYPE_MAPPING = {
    'chambre-louer': {'property_type': 'CHAMBRE_SIMPLE', 'listing_category': 'RENT'},
    'chambre-sdb-louer': {'property_type': 'CHAMBRE_SDB_INTERNE', 'listing_category': 'RENT'},
    'studio-louer': {'property_type': 'STUDIO_SEPARE', 'listing_category': 'RENT'},
    'appartement-louer': {'property_type': 'APARTMENT', 'listing_category': 'RENT'},
    'appartement-vendre': {'property_type': 'APARTMENT', 'listing_category': 'SALE'},
    'villa-louer': {'property_type': 'VILLA', 'listing_category': 'RENT'},
    'villa-vendre': {'property_type': 'VILLA', 'listing_category': 'SALE'},
    'terrain-vendre': {'property_type': 'TERRAIN', 'listing_category': 'SALE'},
    'bureau-louer': {'property_type': 'OFFICE', 'listing_category': 'RENT'},
    'magasin-louer': {'property_type': 'SHOP', 'listing_category': 'RENT'},
    'meuble-dakar': {'listing_category': 'FURNISHED'},
}

# Reverse mapping for URL generation
def get_seo_slug(property_type, listing_category):
    for slug, filters in SEO_TYPE_MAPPING.items():
        if filters.get('property_type') == property_type and filters.get('listing_category') == listing_category:
            return slug
    return None
