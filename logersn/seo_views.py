from django.shortcuts import render, get_object_or_404
from .models import Property
from .seo_utils import SEO_TYPE_MAPPING
from logersn.constants import CITY_CHOICES, PROPERTY_TYPE_CHOICES, LISTING_CATEGORY_CHOICES
from django.core.paginator import Paginator
from django.db.models import Case, When

def seo_search_view(request, type_slug, city_slug=None, neighborhood_slug=None):
    filters = SEO_TYPE_MAPPING.get(type_slug, {})
    if not filters and type_slug != 'immobilier':
        # Fallback or 404
        pass
    
    properties = Property.objects.filter(is_published=True)
    
    # Apply type/category filters
    if 'property_type' in filters:
        properties = properties.filter(property_type=filters['property_type'])
    if 'listing_category' in filters:
        properties = properties.filter(listing_category=filters['listing_category'])
        
    # Apply location filters
    seo_title_parts = []
    
    # Mapping slugs to choices (simplified, assuming slugs are lowercase version of display names)
    if city_slug:
        # On cherche la ville dans CITY_CHOICES
        target_city = None
        for val, label in CITY_CHOICES:
            if label.lower().replace(' ', '-') == city_slug.lower():
                target_city = val
                seo_title_parts.append(label)
                break
        if target_city:
            properties = properties.filter(city=target_city)
            
    if neighborhood_slug:
        # Pour le quartier, on fait un filtrage plus souple
        properties = properties.filter(neighborhood__icontains=neighborhood_slug.replace('-', ' '))
        seo_title_parts.append(neighborhood_slug.replace('-', ' ').title())

    # Sorting (Boost first)
    properties = properties.order_by(
        Case(When(boost_status='ACTIVE', then=0), default=1),
        '-created_at'
    ).select_related('owner').prefetch_related('images')
    
    # Pagination
    paginator = Paginator(properties, 12)
    page_number = request.GET.get('page', 1)
    page_obj = paginator.get_page(page_number)
    
    # SEO Content
    type_label = type_slug.replace('-', ' ').title()
    if city_slug:
        title = f"{type_label} à {city_slug.title()}"
    else:
        title = f"{type_label} au Sénégal"
        
    context = {
        'page_obj': page_obj,
        'seo_title': title,
        'type_slug': type_slug,
        'city_slug': city_slug,
        'neighborhood_slug': neighborhood_slug,
        'property_types': PROPERTY_TYPE_CHOICES,
        'cities': CITY_CHOICES,
    }
    
    return render(request, 'seo_search.html', context)
