from .models import Advertisement, SEOSetting, NohanSetting
from logersn.models import Property

def ads_processor(request):
    """Make ads globally available in templates."""
    try:
        top_ads = Advertisement.objects.filter(location='TOP', is_active=True).order_by('-id')
        bottom_ads = Advertisement.objects.filter(location='BOTTOM', is_active=True).order_by('-id')
        popup_ads = Advertisement.objects.filter(location='POPUP', is_active=True).first()
        pop_under_ads = Advertisement.objects.filter(location='POPUNDER', is_active=True).first()
        sidebar_ads = Advertisement.objects.filter(location='SIDEBAR', is_active=True).order_by('-id')
        in_feed_ads = Advertisement.objects.filter(location='BETWEEN_LISTINGS', is_active=True).order_by('-id')
        left_skin_ads = Advertisement.objects.filter(location='LEFT_SKIN', is_active=True).first()
        right_skin_ads = Advertisement.objects.filter(location='RIGHT_SKIN', is_active=True).first()
        property_popup = Property.objects.filter(is_featured_popup=True, is_published=True).order_by('-id').first()
        seo_settings = SEOSetting.objects.first()
        nohan_setting = NohanSetting.objects.first()
    except Exception:
        top_ads = bottom_ads = sidebar_ads = in_feed_ads = []
        popup_ads = pop_under_ads = property_popup = seo_settings = left_skin_ads = right_skin_ads = nohan_setting = None

    return {
        'ads_top': top_ads,
        'ads_bottom': bottom_ads,
        'ad_popup': popup_ads,
        'ad_pop_under': pop_under_ads,
        'ads_sidebar': sidebar_ads,
        'ads_in_feed': in_feed_ads,
        'ad_left_skin': left_skin_ads,
        'ad_right_skin': right_skin_ads,
        'property_popup': property_popup,
        'seo_settings': seo_settings,
        'nohan_active': nohan_setting.is_active if nohan_setting else False,
    }
